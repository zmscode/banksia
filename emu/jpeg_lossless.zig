//! Lossless JPEG (ITU-T T.81 process 14, SOF3): the entropy coding inside
//! real-world DNGs. Not baseline JPEG — no DCT, no quantization: Huffman
//! coded prediction differences, bit-exact by construction.
//!
//! `decode` is control plane over untrusted bytes: malformed input returns
//! `error.Corrupt`, features outside DNG's profile (restart intervals,
//! non-1x1 sampling) return `error.UnsupportedJpeg`, and nothing asserts.
//! `encode` is the fixture generator that gives the decoder its pair
//! assertion; it asserts freely because fixtures are our own data.
//!
//! DNG maps CFA tiles onto SOF3 scans as interleaved 1x1 components: a
//! mosaic row of W samples is X columns times Nf components, W == X * Nf.
//! Decoded samples land row-major in that same linear order, so the caller
//! treats the output as plain rows.

const std = @import("std");
const assert = std.debug.assert;

pub const Error = error{ Corrupt, UnsupportedJpeg };

pub const components_max: u32 = 4;
const tables_max: u32 = 4;
const huffman_values_max: u32 = 256;
const code_length_max: u32 = 16;

const marker_soi: u8 = 0xD8;
const marker_eoi: u8 = 0xD9;
const marker_sof3: u8 = 0xC3;
const marker_dht: u8 = 0xC4;
const marker_sos: u8 = 0xDA;
const marker_dri: u8 = 0xDD;
const marker_com: u8 = 0xFE;

const Frame = struct {
    precision: u32,
    lines: u32,
    columns: u32,
    component_count: u32,
    /// Component ids as declared, in order; the scan must match this order.
    component_ids: [components_max]u8,
};

const Scan = struct {
    /// Huffman table id per component, in frame order.
    table_ids: [components_max]u8,
    predictor: u32,
    point_transform: u32,
};

/// Decode one SOF3 stream into `out`, validating its dimensions against the
/// caller's expectation: `row_samples` interleaved samples per line
/// (columns * components) over `lines` lines.
pub fn decode(bytes: []const u8, out: []u16, row_samples: u32, lines: u32) Error!void {
    assert(out.len == @as(usize, row_samples) * lines);
    assert(row_samples > 0);
    assert(lines > 0);

    var parser = Parser{ .bytes = bytes };
    try parser.expect_soi();

    var tables: [tables_max]?HuffTable = @splat(null);
    var frame: ?Frame = null;
    var scan: ?Scan = null;
    // Marker loop: strictly forward through the byte stream, so the bound
    // is the input length itself; `pos` advances every iteration.
    while (scan == null) {
        const marker = try parser.marker_next();
        switch (marker) {
            marker_dht => try parser.dht_parse(&tables),
            marker_sof3 => {
                if (frame != null) return error.Corrupt;
                frame = try parser.sof3_parse();
            },
            marker_sos => scan = try parser.sos_parse(&(frame orelse return error.Corrupt)),
            marker_dri => try parser.dri_parse(),
            marker_soi, marker_eoi => return error.Corrupt,
            marker_com, 0xE0...0xEF => try parser.segment_skip(),
            // Any other frame type (baseline, progressive, arithmetic...)
            // is not Huffman lossless JPEG.
            0xC0...0xC2, 0xC5...0xC7, 0xC9...0xCF => return error.UnsupportedJpeg,
            else => return error.Corrupt,
        }
    }

    const f = frame.?;
    const s = scan.?;
    if (f.columns * f.component_count != row_samples) return error.Corrupt;
    if (f.lines != lines) return error.Corrupt;

    var reader = BitReader{ .bytes = bytes, .pos = parser.pos };
    try scan_decode(&reader, f, s, &tables, out, row_samples);
}

fn scan_decode(
    reader: *BitReader,
    frame: Frame,
    scan: Scan,
    tables: *const [tables_max]?HuffTable,
    out: []u16,
    row_samples: u32,
) Error!void {
    assert(out.len == @as(usize, row_samples) * frame.lines);
    // Resolve tables once; a scan naming an undefined table is corrupt.
    var component_tables: [components_max]*const HuffTable = undefined;
    for (0..frame.component_count) |c| {
        const id = scan.table_ids[c];
        component_tables[c] =
            if (tables[id]) |*table| table else return error.Corrupt;
    }

    const shift: u5 = @intCast(frame.precision - scan.point_transform - 1);
    const predictor_default = @as(i32, 1) << shift;
    const nf = frame.component_count;

    var index: usize = 0;
    var y: u32 = 0;
    while (y < frame.lines) : (y += 1) {
        var column: u32 = 0;
        while (column < frame.columns) : (column += 1) {
            var c: u32 = 0;
            while (c < nf) : (c += 1) {
                const category = try huffman_decode(reader, component_tables[c]);
                if (category > 16) return error.Corrupt;
                const difference: i32 = if (category == 16)
                    32768
                else
                    extend(try reader.bits(category), category);
                const predicted = predict(
                    out,
                    index,
                    row_samples,
                    nf,
                    y,
                    column,
                    scan.predictor,
                    predictor_default,
                );
                out[index] = @intCast(@as(u32, @bitCast(predicted + difference)) & 0xFFFF);
                index += 1;
            }
        }
    }
    assert(index == out.len);

    if (scan.point_transform > 0) {
        const up: u4 = @intCast(scan.point_transform);
        for (out) |*sample| sample.* <<= up;
    }
}

/// T.81 H.1.2.1. The first sample of the scan seeds from mid-range; the
/// rest of the first line predicts left, the first column predicts above,
/// and everything else uses the scan's selected predictor.
fn predict(
    out: []const u16,
    index: usize,
    row_samples: u32,
    nf: u32,
    y: u32,
    column: u32,
    predictor: u32,
    default: i32,
) i32 {
    if (y == 0 and column == 0) return default;
    if (y == 0) return out[index - nf]; // Ra
    if (column == 0) return out[index - row_samples]; // Rb
    const ra: i32 = out[index - nf];
    const rb: i32 = out[index - row_samples];
    const rc: i32 = out[index - row_samples - nf];
    return switch (predictor) {
        1 => ra,
        2 => rb,
        3 => rc,
        4 => ra + rb - rc,
        5 => ra + ((rb - rc) >> 1),
        6 => rb + ((ra - rc) >> 1),
        7 => (ra + rb) >> 1,
        else => unreachable, // validated when the scan header was parsed
    };
}

/// T.81 F.2.2.1 EXTEND: an SSSS-bit value becomes a signed difference.
fn extend(value: u32, category: u32) i32 {
    assert(category <= 15);
    if (category == 0) return 0;
    const half = @as(u32, 1) << @intCast(category - 1);
    if (value < half) {
        const full = (@as(u32, 1) << @intCast(category)) - 1;
        return @as(i32, @intCast(value)) - @as(i32, @intCast(full));
    }
    return @intCast(value);
}

// ---- marker parsing -----------------------------------------------------------

const Parser = struct {
    bytes: []const u8,
    pos: u32 = 0,

    fn byte_next(self: *Parser) Error!u8 {
        if (self.pos >= self.bytes.len) return error.Corrupt;
        const b = self.bytes[self.pos];
        self.pos += 1;
        return b;
    }

    fn u16_next(self: *Parser) Error!u16 {
        const hi = try self.byte_next();
        const lo = try self.byte_next();
        return (@as(u16, hi) << 8) | lo;
    }

    fn expect_soi(self: *Parser) Error!void {
        if (try self.byte_next() != 0xFF) return error.Corrupt;
        if (try self.byte_next() != marker_soi) return error.Corrupt;
    }

    /// The next marker code, skipping fill bytes (0xFF may repeat).
    fn marker_next(self: *Parser) Error!u8 {
        if (try self.byte_next() != 0xFF) return error.Corrupt;
        var code = try self.byte_next();
        while (code == 0xFF) code = try self.byte_next();
        if (code == 0x00) return error.Corrupt; // stuffing outside a scan
        return code;
    }

    /// Length field of the current segment, exclusive of itself.
    fn segment_length(self: *Parser) Error!u32 {
        const length = try self.u16_next();
        if (length < 2) return error.Corrupt;
        return length - 2;
    }

    fn segment_skip(self: *Parser) Error!void {
        const length = try self.segment_length();
        if (@as(u64, self.pos) + length > self.bytes.len) return error.Corrupt;
        self.pos += length;
    }

    fn dri_parse(self: *Parser) Error!void {
        if (try self.segment_length() != 2) return error.Corrupt;
        // Restart intervals never appear in DNG streams; reject rather than
        // decode them wrong.
        if (try self.u16_next() != 0) return error.UnsupportedJpeg;
    }

    fn sof3_parse(self: *Parser) Error!Frame {
        const length = try self.segment_length();
        const precision = try self.byte_next();
        const lines = try self.u16_next();
        const columns = try self.u16_next();
        const component_count = try self.byte_next();
        if (precision < 2 or precision > 16) return error.Corrupt;
        if (lines == 0 or columns == 0) return error.Corrupt; // no DNL support
        if (component_count == 0 or component_count > components_max) {
            return error.UnsupportedJpeg;
        }
        if (length != 6 + @as(u32, component_count) * 3) return error.Corrupt;

        var frame = Frame{
            .precision = precision,
            .lines = lines,
            .columns = columns,
            .component_count = component_count,
            .component_ids = undefined,
        };
        for (0..component_count) |c| {
            frame.component_ids[c] = try self.byte_next();
            const sampling = try self.byte_next();
            if (sampling != 0x11) return error.UnsupportedJpeg; // 1x1 only
            _ = try self.byte_next(); // Tq, meaningless in lossless
        }
        return frame;
    }

    fn sos_parse(self: *Parser, frame: *const Frame) Error!Scan {
        const length = try self.segment_length();
        const component_count = try self.byte_next();
        if (component_count != frame.component_count) return error.UnsupportedJpeg;
        if (length != 4 + @as(u32, component_count) * 2) return error.Corrupt;

        var scan = Scan{
            .table_ids = undefined,
            .predictor = undefined,
            .point_transform = undefined,
        };
        for (0..component_count) |c| {
            const id = try self.byte_next();
            // Interleave order must match the frame; DNG always does.
            if (id != frame.component_ids[c]) return error.UnsupportedJpeg;
            const table_ids = try self.byte_next();
            if (table_ids & 0x0F != 0) return error.Corrupt; // no AC table
            scan.table_ids[c] = table_ids >> 4;
            if (scan.table_ids[c] >= tables_max) return error.Corrupt;
        }
        const predictor = try self.byte_next(); // Ss
        if (predictor < 1 or predictor > 7) return error.Corrupt;
        scan.predictor = predictor;
        if (try self.byte_next() != 0) return error.Corrupt; // Se
        const approximation = try self.byte_next(); // Ah:Al
        if (approximation >> 4 != 0) return error.Corrupt;
        scan.point_transform = approximation & 0x0F;
        if (scan.point_transform >= frame.precision) return error.Corrupt;
        return scan;
    }

    fn dht_parse(self: *Parser, tables: *[tables_max]?HuffTable) Error!void {
        var remaining = try self.segment_length();
        // A DHT segment holds one or more tables back to back; each is at
        // least 17 bytes, so the loop is bounded by the segment length.
        while (remaining > 0) {
            if (remaining < 17) return error.Corrupt;
            const class_and_id = try self.byte_next();
            if (class_and_id >> 4 != 0) return error.Corrupt; // DC class only
            const id = class_and_id & 0x0F;
            if (id >= tables_max) return error.Corrupt;

            var counts: [code_length_max]u8 = undefined;
            var total: u32 = 0;
            for (&counts) |*count| {
                count.* = try self.byte_next();
                total += count.*;
            }
            if (total == 0 or total > huffman_values_max) return error.Corrupt;
            if (remaining < 17 + total) return error.Corrupt;
            var values: [huffman_values_max]u8 = undefined;
            for (values[0..total]) |*value| value.* = try self.byte_next();

            tables[id] = try HuffTable.build(counts, values[0..total]);
            remaining -= 17 + total;
        }
    }
};

// ---- Huffman ------------------------------------------------------------------

const HuffTable = struct {
    /// Per code length 1..16 (index 0 unused): the canonical bounds and the
    /// index of the first value of that length. -1 marks an empty length.
    min_code: [code_length_max + 1]i32,
    max_code: [code_length_max + 1]i32,
    value_index: [code_length_max + 1]u32,
    values: [huffman_values_max]u8,

    /// Canonical construction per T.81 C.2; rejects overfull tables.
    fn build(counts: [code_length_max]u8, values: []const u8) Error!HuffTable {
        assert(values.len <= huffman_values_max);
        var table = HuffTable{
            .min_code = @splat(0),
            .max_code = @splat(-1),
            .value_index = @splat(0),
            .values = undefined,
        };
        @memcpy(table.values[0..values.len], values);

        var code: u32 = 0;
        var index: u32 = 0;
        for (1..code_length_max + 1) |length| {
            const count = counts[length - 1];
            if (code + count > (@as(u32, 1) << @intCast(length))) return error.Corrupt;
            table.value_index[length] = index;
            table.min_code[length] = @intCast(code);
            table.max_code[length] = @as(i32, @intCast(code)) + count - 1;
            code = (code + count) << 1;
            index += count;
        }
        if (index != values.len) return error.Corrupt;
        return table;
    }
};

fn huffman_decode(reader: *BitReader, table: *const HuffTable) Error!u8 {
    var code: i32 = @intCast(try reader.bit());
    var length: u32 = 1;
    while (length <= code_length_max) : (length += 1) {
        if (code <= table.max_code[length]) {
            const offset: u32 = @intCast(code - table.min_code[length]);
            return table.values[table.value_index[length] + offset];
        }
        code = (code << 1) | @as(i32, @intCast(try reader.bit()));
    }
    return error.Corrupt;
}

const BitReader = struct {
    bytes: []const u8,
    pos: u32,
    buffer: u32 = 0,
    count: u32 = 0,

    fn bit(self: *BitReader) Error!u32 {
        if (self.count == 0) {
            if (self.pos >= self.bytes.len) return error.Corrupt;
            const b = self.bytes[self.pos];
            self.pos += 1;
            if (b == 0xFF) {
                // Entropy-coded 0xFF is stuffed as FF 00; a real marker in
                // the middle of the scan means a truncated stream.
                if (self.pos >= self.bytes.len) return error.Corrupt;
                if (self.bytes[self.pos] != 0x00) return error.Corrupt;
                self.pos += 1;
            }
            self.buffer = b;
            self.count = 8;
        }
        self.count -= 1;
        return (self.buffer >> @intCast(self.count)) & 1;
    }

    fn bits(self: *BitReader, n: u32) Error!u32 {
        assert(n <= 16);
        var value: u32 = 0;
        var i: u32 = 0;
        while (i < n) : (i += 1) value = (value << 1) | try self.bit();
        return value;
    }
};

// ---- encoder: the fixture generator ---------------------------------------------

/// One Huffman table for every fixture: all 17 categories at code length 5.
/// Wasteful and trivially canonical — fixtures optimize for obviousness.
const fixture_counts: [code_length_max]u8 = blk: {
    var counts: [code_length_max]u8 = @splat(0);
    counts[4] = 17;
    break :blk counts;
};
const fixture_code_bits: u32 = 5;

/// Encode samples as a single-scan SOF3 stream (predictor 1, no point
/// transform) that `decode` reads back bit-exactly. Inputs are our own
/// fixtures: asserts, not errors.
pub fn encode(
    gpa: std.mem.Allocator,
    samples: []const u16,
    row_samples: u32,
    lines: u32,
    component_count: u32,
    precision: u32,
) error{OutOfMemory}![]u8 {
    assert(component_count >= 1);
    assert(component_count <= components_max);
    assert(row_samples % component_count == 0);
    const columns = row_samples / component_count;
    assert(columns > 0);
    assert(columns <= 65535);
    assert(lines > 0);
    assert(lines <= 65535);
    assert(samples.len == @as(usize, row_samples) * lines);
    assert(precision >= 2);
    assert(precision <= 16);
    if (precision < 16) {
        for (samples) |sample| assert(sample < @as(u32, 1) << @intCast(precision));
    }

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(gpa);
    try header_append(gpa, &out, columns, lines, component_count, precision);

    var writer = BitWriter{ .gpa = gpa, .out = &out };
    const predictor_default = @as(i32, 1) << @intCast(precision - 1);
    for (samples, 0..) |sample, index| {
        const y: u32 = @intCast(index / row_samples);
        const column: u32 = @intCast((index % row_samples) / component_count);
        const predicted = predict(
            samples,
            index,
            row_samples,
            component_count,
            y,
            column,
            1,
            predictor_default,
        );
        try difference_append(&writer, @as(i32, sample) - predicted);
    }
    try writer.flush();

    try out.appendSlice(gpa, &.{ 0xFF, marker_eoi });
    return out.toOwnedSlice(gpa);
}

fn header_append(
    gpa: std.mem.Allocator,
    out: *std.ArrayList(u8),
    columns: u32,
    lines: u32,
    component_count: u32,
    precision: u32,
) error{OutOfMemory}!void {
    try out.appendSlice(gpa, &.{ 0xFF, marker_soi });

    // DHT: one DC-class table, id 0, the fixed fixture table.
    try out.appendSlice(gpa, &.{ 0xFF, marker_dht, 0, 17 + 2 + 17, 0x00 });
    try out.appendSlice(gpa, &fixture_counts);
    for (0..17) |category| try out.append(gpa, @intCast(category));

    // SOF3: every component 1x1, quantization slot unused.
    try out.appendSlice(gpa, &.{ 0xFF, marker_sof3, 0, @intCast(8 + component_count * 3) });
    try out.append(gpa, @intCast(precision));
    try out.appendSlice(gpa, &.{ @intCast(lines >> 8), @intCast(lines & 0xFF) });
    try out.appendSlice(gpa, &.{ @intCast(columns >> 8), @intCast(columns & 0xFF) });
    try out.append(gpa, @intCast(component_count));
    for (0..component_count) |c| {
        try out.appendSlice(gpa, &.{ @intCast(c), 0x11, 0 });
    }

    // SOS: all components on table 0, predictor 1, no point transform.
    try out.appendSlice(gpa, &.{ 0xFF, marker_sos, 0, @intCast(6 + component_count * 2) });
    try out.append(gpa, @intCast(component_count));
    for (0..component_count) |c| {
        try out.appendSlice(gpa, &.{ @intCast(c), 0x00 });
    }
    try out.appendSlice(gpa, &.{ 1, 0, 0 }); // Ss = predictor 1, Se, Ah:Al
}

fn difference_append(writer: *BitWriter, difference_raw: i32) error{OutOfMemory}!void {
    // Differences live modulo 2^16 (T.81 H.1.2.1); wrap into i16 range so
    // the category never exceeds 16.
    const wrapped: i16 = @bitCast(@as(u16, @truncate(@as(u32, @bitCast(difference_raw)))));
    const difference: i32 = wrapped;
    if (difference == -32768) {
        // Category 16 carries no extra bits: the difference is exactly
        // 32768 ≡ -32768 (mod 2^16).
        try writer.put(16, fixture_code_bits);
        return;
    }
    const magnitude: u32 = @abs(difference);
    const category: u32 = 32 - @clz(magnitude);
    assert(category <= 15);
    try writer.put(category, fixture_code_bits);
    if (category == 0) return;
    const value: u32 = if (difference < 0)
        @as(u32, @bitCast(difference + (@as(i32, 1) << @intCast(category)) - 1))
    else
        magnitude;
    try writer.put(value & ((@as(u32, 1) << @intCast(category)) - 1), category);
}

const BitWriter = struct {
    gpa: std.mem.Allocator,
    out: *std.ArrayList(u8),
    buffer: u32 = 0,
    count: u32 = 0,

    fn put(self: *BitWriter, value: u32, n: u32) error{OutOfMemory}!void {
        assert(n >= 1);
        assert(n <= 16);
        assert(value < @as(u32, 1) << @intCast(n));
        var i: u32 = 0;
        while (i < n) : (i += 1) {
            const bit_value = (value >> @intCast(n - 1 - i)) & 1;
            self.buffer = (self.buffer << 1) | bit_value;
            self.count += 1;
            if (self.count == 8) try self.byte_flush();
        }
    }

    /// Pad the final partial byte with 1-bits, as the spec prescribes.
    fn flush(self: *BitWriter) error{OutOfMemory}!void {
        while (self.count != 0) try self.put(1, 1);
    }

    fn byte_flush(self: *BitWriter) error{OutOfMemory}!void {
        assert(self.count == 8);
        const byte: u8 = @intCast(self.buffer & 0xFF);
        try self.out.append(self.gpa, byte);
        if (byte == 0xFF) try self.out.append(self.gpa, 0x00); // stuffing
        self.buffer = 0;
        self.count = 0;
    }
};

// ---- tests ---------------------------------------------------------------------

fn test_roundtrip(
    gpa: std.mem.Allocator,
    samples: []const u16,
    row_samples: u32,
    lines: u32,
    component_count: u32,
    precision: u32,
) !void {
    const stream = try encode(gpa, samples, row_samples, lines, component_count, precision);
    defer gpa.free(stream);
    const decoded = try gpa.alloc(u16, samples.len);
    defer gpa.free(decoded);
    try decode(stream, decoded, row_samples, lines);
    try std.testing.expectEqualSlices(u16, samples, decoded);
}

test "encode/decode roundtrip across shapes, components, and precisions" {
    const gpa = std.testing.allocator;

    // Deterministic values with full-range jumps: exercises every category
    // including the sign paths, at three precisions.
    inline for ([_]u32{ 8, 12, 16 }) |precision| {
        var samples: [7 * 5 * 2]u16 = undefined;
        for (&samples, 0..) |*sample, i| {
            const z = splitmix64(i + precision);
            sample.* = @intCast(z % (@as(u64, 1) << @intCast(precision)));
        }
        try test_roundtrip(gpa, &samples, 7 * 2, 5, 2, precision);
        try test_roundtrip(gpa, &samples, 7 * 2, 5, 1, precision);
    }

    // Degenerate shapes: single sample, single row, single column.
    try test_roundtrip(gpa, &.{12345}, 1, 1, 1, 16);
    try test_roundtrip(gpa, &.{ 0, 65535, 1, 65534 }, 4, 1, 1, 16);
    try test_roundtrip(gpa, &.{ 9, 90, 900, 9000 }, 1, 4, 1, 16);
}

test "difference wraparound survives the modulo arithmetic (negative space)" {
    const gpa = std.testing.allocator;
    // 0 -> 65535 -> 0 -> 32768: differences of -32768 magnitude and beyond,
    // the category-16 special case both directions.
    try test_roundtrip(gpa, &.{ 0, 65535, 0, 32768, 0 }, 5, 1, 1, 16);
}

test "corrupt and truncated streams error, never crash" {
    const gpa = std.testing.allocator;
    var out: [4]u16 = undefined;

    try std.testing.expectError(error.Corrupt, decode("", &out, 4, 1));
    try std.testing.expectError(error.Corrupt, decode("\xff\xd8", &out, 4, 1));
    try std.testing.expectError(error.Corrupt, decode("not a jpeg", &out, 4, 1));

    const stream = try encode(gpa, &.{ 1, 2, 3, 4 }, 4, 1, 1, 16);
    defer gpa.free(stream);
    // Every truncation of a valid stream must fail cleanly.
    var length: usize = 0;
    while (length < stream.len - 2) : (length += 1) {
        try std.testing.expectError(error.Corrupt, decode(stream[0..length], &out, 4, 1));
    }
    // Dimension mismatches are the caller's tripwire.
    try std.testing.expectError(error.Corrupt, decode(stream, out[0..2], 2, 1));

    // A baseline JPEG SOF is not lossless.
    const baseline = "\xff\xd8\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x00\x11\x00";
    var one: [1]u16 = undefined;
    try std.testing.expectError(error.UnsupportedJpeg, decode(baseline, &one, 1, 1));
}

/// The doctrine generator: integer in, integer out, reproducible forever.
fn splitmix64(state: u64) u64 {
    var z = state +% 0x9E3779B97F4A7C15;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}
