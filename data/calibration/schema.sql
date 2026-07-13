PRAGMA foreign_keys = ON;

CREATE TABLE bundle_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE input_profile (
    profile_id TEXT PRIMARY KEY,
    byte_size INTEGER NOT NULL CHECK (byte_size > 0),
    sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
    profile_size INTEGER NOT NULL CHECK (profile_size > 0),
    version_hex TEXT NOT NULL,
    device_class TEXT NOT NULL,
    color_space TEXT NOT NULL,
    pcs TEXT NOT NULL,
    created TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    model TEXT NOT NULL,
    tag_count INTEGER NOT NULL CHECK (tag_count > 0)
) WITHOUT ROWID;

CREATE TABLE input_profile_tag (
    profile_id TEXT NOT NULL REFERENCES input_profile(profile_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    signature TEXT NOT NULL,
    file_offset INTEGER NOT NULL CHECK (file_offset >= 0),
    byte_size INTEGER NOT NULL CHECK (byte_size > 0),
    type_signature TEXT,
    payload BLOB NOT NULL,
    PRIMARY KEY (profile_id, ordinal)
) WITHOUT ROWID;

CREATE INDEX input_profile_tag_signature
ON input_profile_tag(profile_id, signature);

CREATE TABLE input_profile_xyz (
    profile_id TEXT NOT NULL,
    tag_ordinal INTEGER NOT NULL,
    value_ordinal INTEGER NOT NULL CHECK (value_ordinal >= 0),
    x REAL NOT NULL,
    y REAL NOT NULL,
    z REAL NOT NULL,
    PRIMARY KEY (profile_id, tag_ordinal, value_ordinal),
    FOREIGN KEY (profile_id, tag_ordinal)
        REFERENCES input_profile_tag(profile_id, ordinal)
) WITHOUT ROWID;

CREATE TABLE input_profile_curve (
    profile_id TEXT NOT NULL,
    tag_ordinal INTEGER NOT NULL,
    value_ordinal INTEGER NOT NULL CHECK (value_ordinal >= 0),
    value_u16 INTEGER NOT NULL CHECK (value_u16 BETWEEN 0 AND 65535),
    PRIMARY KEY (profile_id, tag_ordinal, value_ordinal),
    FOREIGN KEY (profile_id, tag_ordinal)
        REFERENCES input_profile_tag(profile_id, ordinal)
) WITHOUT ROWID;

CREATE TABLE input_profile_mft2 (
    profile_id TEXT NOT NULL,
    tag_ordinal INTEGER NOT NULL,
    input_channels INTEGER NOT NULL CHECK (input_channels > 0),
    output_channels INTEGER NOT NULL CHECK (output_channels > 0),
    grid_points INTEGER NOT NULL CHECK (grid_points > 1),
    matrix_s15fixed16 BLOB NOT NULL,
    input_entries INTEGER NOT NULL CHECK (input_entries > 0),
    output_entries INTEGER NOT NULL CHECK (output_entries > 0),
    input_tables_u16be BLOB NOT NULL,
    clut_u16be BLOB NOT NULL,
    output_tables_u16be BLOB NOT NULL,
    PRIMARY KEY (profile_id, tag_ordinal),
    FOREIGN KEY (profile_id, tag_ordinal)
        REFERENCES input_profile_tag(profile_id, ordinal)
) WITHOUT ROWID;

CREATE TABLE film_curve (
    curve_id TEXT PRIMARY KEY,
    source_name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT NOT NULL,
    format_version INTEGER NOT NULL CHECK (format_version > 0),
    flags INTEGER NOT NULL CHECK (flags >= 0)
) WITHOUT ROWID;

CREATE TABLE film_curve_point (
    curve_id TEXT NOT NULL REFERENCES film_curve(curve_id),
    component TEXT NOT NULL CHECK (component IN ('film', 'ccd', 'contrast')),
    point_index INTEGER NOT NULL CHECK (point_index >= 0),
    x REAL NOT NULL,
    y REAL NOT NULL,
    PRIMARY KEY (curve_id, component, point_index)
) WITHOUT ROWID;

CREATE TABLE camera (
    camera_id TEXT PRIMARY KEY,
    source_camera_id TEXT NOT NULL UNIQUE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    create_date TEXT,
    update_date TEXT,
    input_profile_id TEXT NOT NULL REFERENCES input_profile(profile_id),
    film_curve_id TEXT NOT NULL REFERENCES film_curve(curve_id)
) WITHOUT ROWID;

CREATE TABLE camera_alias (
    camera_id TEXT NOT NULL REFERENCES camera(camera_id),
    make_normalized TEXT NOT NULL,
    model_normalized TEXT NOT NULL,
    PRIMARY KEY (make_normalized, model_normalized)
) WITHOUT ROWID;

CREATE TABLE camera_property (
    camera_id TEXT NOT NULL REFERENCES camera(camera_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    name TEXT NOT NULL,
    value TEXT,
    PRIMARY KEY (camera_id, ordinal)
) WITHOUT ROWID;

CREATE TABLE camera_iso (
    iso_record_id TEXT PRIMARY KEY,
    camera_id TEXT NOT NULL REFERENCES camera(camera_id),
    iso REAL NOT NULL CHECK (iso >= 0),
    iso_ordinal INTEGER NOT NULL CHECK (iso_ordinal >= 0),
    UNIQUE (camera_id, iso_ordinal)
) WITHOUT ROWID;

CREATE TABLE camera_iso_property (
    camera_id TEXT NOT NULL REFERENCES camera(camera_id),
    iso REAL NOT NULL CHECK (iso >= 0),
    iso_ordinal INTEGER NOT NULL CHECK (iso_ordinal >= 0),
    property_ordinal INTEGER NOT NULL CHECK (property_ordinal >= 0),
    name TEXT NOT NULL,
    value TEXT,
    PRIMARY KEY (camera_id, iso_ordinal, property_ordinal),
    FOREIGN KEY (camera_id, iso_ordinal)
        REFERENCES camera_iso(camera_id, iso_ordinal)
) WITHOUT ROWID;

CREATE INDEX camera_iso_lookup
ON camera_iso_property(camera_id, iso, name);

CREATE TABLE lens (
    lens_id TEXT PRIMARY KEY,
    type TEXT,
    full_name TEXT NOT NULL,
    short_name TEXT NOT NULL,
    brand TEXT,
    mount TEXT
) WITHOUT ROWID;

CREATE TABLE lens_alias (
    lens_id TEXT NOT NULL REFERENCES lens(lens_id),
    name_normalized TEXT NOT NULL PRIMARY KEY
) WITHOUT ROWID;

CREATE TABLE lens_node (
    lens_id TEXT NOT NULL REFERENCES lens(lens_id),
    node_id INTEGER NOT NULL CHECK (node_id >= 0),
    parent_id INTEGER,
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    name TEXT NOT NULL,
    text_value TEXT,
    PRIMARY KEY (lens_id, node_id)
) WITHOUT ROWID;

CREATE INDEX lens_node_name ON lens_node(lens_id, name);

CREATE TABLE lens_attribute (
    lens_id TEXT NOT NULL,
    node_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    value TEXT NOT NULL,
    PRIMARY KEY (lens_id, node_id, name),
    FOREIGN KEY (lens_id, node_id) REFERENCES lens_node(lens_id, node_id)
) WITHOUT ROWID;
