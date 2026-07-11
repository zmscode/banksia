// Decompile the Capture One ImageCore functions that define and expose film curves.
// @category CaptureOne

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolIterator;

public class DecompileCaptureOneCurves extends GhidraScript {
    private static final List<String> TARGETS = List.of(
        "CreatePOFilmCurve",
        "DeserialiseFilmCurveData",
        "POFilmCurveGetCurve",
        "POFilmCurveGetCCDCurve",
        "POFilmCurveGetContrastCurve",
        "POGradationCurveGetNumberOfPoints",
        "POGradationCurveGetXAtIndex",
        "POGradationCurveGetYAtIndex",
        "IC_GetDefaultProcessSettings",
        "IC_GetDefaultImageProcessSettings",
        "IC_GetDefaultCameraProcessSettings"
    );

    @Override
    public void run() throws Exception {
        if (getScriptArgs().length < 1) {
            throw new IllegalArgumentException("expected output path and optional symbol substrings");
        }
        List<String> targets = TARGETS;
        if (getScriptArgs().length > 1) {
            targets = List.of(getScriptArgs()).subList(1, getScriptArgs().length);
        }

        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        try (PrintWriter output = new PrintWriter(new File(getScriptArgs()[0]))) {
            List<Symbol> symbols = new ArrayList<>();
            SymbolIterator iterator = currentProgram.getSymbolTable().getAllSymbols(true);
            while (iterator.hasNext()) {
                Symbol symbol = iterator.next();
                if (matches(symbol.getName(true), targets)) {
                    symbols.add(symbol);
                }
            }

            for (Symbol symbol : symbols) {
                if (monitor.isCancelled()) {
                    break;
                }
                Function function = getFunctionAt(symbol.getAddress());
                if (function == null) {
                    new DisassembleCommand(symbol.getAddress(), null, true)
                        .applyTo(currentProgram, monitor);
                    function = createFunction(symbol.getAddress(), symbol.getName());
                }
                if (function == null) {
                    continue;
                }
                String name = symbol.getName(true);
                output.printf("/* %s @ %s */%n", name, function.getEntryPoint());
                DecompileResults result = decompiler.decompileFunction(function, 120, monitor);
                if (result.decompileCompleted()) {
                    output.println(result.getDecompiledFunction().getC());
                } else {
                    output.printf("/* decompilation failed: %s */%n%n", result.getErrorMessage());
                }
            }
        } finally {
            decompiler.dispose();
        }
    }

    private static boolean matches(String name, List<String> targets) {
        for (String target : targets) {
            if (name.contains(target)) {
                return true;
            }
        }
        return false;
    }
}
