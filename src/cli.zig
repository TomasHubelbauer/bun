const bun = @import("bun");
const string = bun.string;
const Output = bun.Output;
const Global = bun.Global;
const Environment = bun.Environment;
const strings = bun.strings;
const default_allocator = bun.default_allocator;
const FeatureFlags = bun.FeatureFlags;

const std = @import("std");
const logger = bun.logger;
const options = @import("options.zig");
const js_ast = bun.JSAst;
const RegularExpression = bun.RegularExpression;
const builtin = @import("builtin");
const File = bun.sys.File;

const debug = Output.scoped(.CLI, true);

const sync = @import("./sync.zig");
const Api = @import("api/schema.zig").Api;
const resolve_path = @import("./resolver/resolve_path.zig");
const clap = bun.clap;
const BunJS = @import("./bun_js.zig");
const Install = @import("./install/install.zig");
const transpiler = bun.transpiler;
const DotEnv = @import("./env_loader.zig");
const RunCommand_ = @import("./cli/run_command.zig").RunCommand;
const FilterRun = @import("./cli/filter_run.zig");

const fs = @import("fs.zig");

const MacroMap = @import("./resolver/package_json.zig").MacroMap;
const TestCommand = @import("./cli/test_command.zig").TestCommand;
pub var start_time: i128 = undefined;
const Bunfig = @import("./bunfig.zig").Bunfig;
const OOM = bun.OOM;

export var Bun__Node__ZeroFillBuffers = false;
export var Bun__Node__ProcessNoDeprecation = false;
export var Bun__Node__ProcessThrowDeprecation = false;

pub var Bun__Node__ProcessTitle: ?string = null;

pub const Cli = struct {
    pub const CompileTarget = @import("./compile_target.zig");
    var wait_group: sync.WaitGroup = undefined;
    pub var log_: logger.Log = undefined;
    pub fn startTransform(_: std.mem.Allocator, _: Api.TransformOptions, _: *logger.Log) anyerror!void {}
    pub fn start(allocator: std.mem.Allocator) void {
        is_main_thread = true;
        start_time = std.time.nanoTimestamp();
        log_ = logger.Log.init(allocator);

        var log = &log_;

        // var panicker = MainPanicHandler.init(log);
        // MainPanicHandler.Singleton = &panicker;
        Command.start(allocator, log) catch |err| {
            log.print(Output.errorWriter()) catch {};

            bun.crash_handler.handleRootError(err, @errorReturnTrace());
        };
    }

    pub var cmd: ?Command.Tag = null;
    pub threadlocal var is_main_thread: bool = false;
};

pub const debug_flags = if (Environment.show_crash_trace) struct {
    var resolve_breakpoints: []const []const u8 = &.{};
    var print_breakpoints: []const []const u8 = &.{};

    pub fn hasResolveBreakpoint(str: []const u8) bool {
        for (resolve_breakpoints) |bp| {
            if (strings.contains(str, bp)) {
                return true;
            }
        }
        return false;
    }

    pub fn hasPrintBreakpoint(path: fs.Path) bool {
        for (print_breakpoints) |bp| {
            if (strings.contains(path.pretty, bp)) {
                return true;
            }
            if (strings.contains(path.text, bp)) {
                return true;
            }
        }
        return false;
    }
} else @compileError("Do not access this namespace in a release build");

const ColonListType = @import("./cli/colon_list_type.zig").ColonListType;
pub const LoaderColonList = ColonListType(Api.Loader, Arguments.loader_resolver);
pub const DefineColonList = ColonListType(string, Arguments.noop_resolver);
fn invalidTarget(diag: *clap.Diagnostic, _target: []const u8) noreturn {
    @branchHint(.cold);
    diag.name.long = "target";
    diag.arg = _target;
    diag.report(Output.errorWriter(), error.InvalidTarget) catch {};
    std.process.exit(1);
}

pub const BuildCommand = @import("./cli/build_command.zig").BuildCommand;
pub const AddCommand = @import("./cli/add_command.zig").AddCommand;
pub const CreateCommand = @import("./cli/create_command.zig").CreateCommand;
pub const CreateCommandExample = @import("./cli/create_command.zig").Example;
pub const CreateListExamplesCommand = @import("./cli/create_command.zig").CreateListExamplesCommand;
pub const DiscordCommand = @import("./cli/discord_command.zig").DiscordCommand;
pub const InstallCommand = @import("./cli/install_command.zig").InstallCommand;
pub const LinkCommand = @import("./cli/link_command.zig").LinkCommand;
pub const UnlinkCommand = @import("./cli/unlink_command.zig").UnlinkCommand;
pub const InstallCompletionsCommand = @import("./cli/install_completions_command.zig").InstallCompletionsCommand;
pub const PackageManagerCommand = @import("./cli/package_manager_command.zig").PackageManagerCommand;
pub const RemoveCommand = @import("./cli/remove_command.zig").RemoveCommand;
pub const RunCommand = @import("./cli/run_command.zig").RunCommand;
pub const ShellCompletions = @import("./cli/shell_completions.zig");
pub const UpdateCommand = @import("./cli/update_command.zig").UpdateCommand;
pub const UpgradeCommand = @import("./cli/upgrade_command.zig").UpgradeCommand;
pub const BunxCommand = @import("./cli/bunx_command.zig").BunxCommand;
pub const ExecCommand = @import("./cli/exec_command.zig").ExecCommand;
pub const PatchCommand = @import("./cli/patch_command.zig").PatchCommand;
pub const PatchCommitCommand = @import("./cli/patch_commit_command.zig").PatchCommitCommand;
pub const OutdatedCommand = @import("./cli/outdated_command.zig").OutdatedCommand;
pub const PublishCommand = @import("./cli/publish_command.zig").PublishCommand;
pub const PackCommand = @import("./cli/pack_command.zig").PackCommand;
pub const AuditCommand = @import("./cli/audit_command.zig").AuditCommand;
pub const InitCommand = @import("./cli/init_command.zig").InitCommand;

pub const Arguments = struct {
    pub fn loader_resolver(in: string) !Api.Loader {
        const option_loader = options.Loader.fromString(in) orelse return error.InvalidLoader;
        return option_loader.toAPI();
    }

    pub fn noop_resolver(in: string) !string {
        return in;
    }

    pub fn fileReadError(err: anyerror, stderr: anytype, filename: string, kind: string) noreturn {
        stderr.writer().print("Error reading file \"{s}\" for {s}: {s}", .{ filename, kind, @errorName(err) }) catch {};
        std.process.exit(1);
    }

    pub fn readFile(
        allocator: std.mem.Allocator,
        cwd: string,
        filename: string,
    ) ![]u8 {
        var paths = [_]string{ cwd, filename };
        const outpath = try std.fs.path.resolve(allocator, &paths);
        defer allocator.free(outpath);
        var file = try bun.openFileZ(&try std.posix.toPosixPath(outpath), std.fs.File.OpenFlags{ .mode = .read_only });
        defer file.close();
        const size = try file.getEndPos();
        return try file.readToEndAlloc(allocator, size);
    }

    pub fn resolve_jsx_runtime(str: string) !Api.JsxRuntime {
        if (strings.eqlComptime(str, "automatic")) {
            return Api.JsxRuntime.automatic;
        } else if (strings.eqlComptime(str, "fallback") or strings.eqlComptime(str, "classic")) {
            return Api.JsxRuntime.classic;
        } else if (strings.eqlComptime(str, "solid")) {
            return Api.JsxRuntime.solid;
        } else {
            return error.InvalidJSXRuntime;
        }
    }

    pub const ParamType = clap.Param(clap.Help);

    const base_params_ = (if (Environment.show_crash_trace) debug_params else [_]ParamType{}) ++ [_]ParamType{
        clap.parseParam("--env-file <STR>...               Load environment variables from the specified file(s)") catch unreachable,
        clap.parseParam("--cwd <STR>                       Absolute path to resolve files & entry points from. This just changes the process' cwd.") catch unreachable,
        clap.parseParam("-c, --config <PATH>?              Specify path to Bun config file. Default <d>$cwd<r>/bunfig.toml") catch unreachable,
        clap.parseParam("-h, --help                        Display this menu and exit") catch unreachable,
    } ++ (if (builtin.have_error_return_tracing) [_]ParamType{
        // This will print more error return traces, as a debug aid
        clap.parseParam("--verbose-error-trace             Dump error return traces") catch unreachable,
    } else [_]ParamType{}) ++ [_]ParamType{
        clap.parseParam("<POS>...") catch unreachable,
    };

    const debug_params = [_]ParamType{
        clap.parseParam("--breakpoint-resolve <STR>...     DEBUG MODE: breakpoint when resolving something that includes this string") catch unreachable,
        clap.parseParam("--breakpoint-print <STR>...       DEBUG MODE: breakpoint when printing something that includes this string") catch unreachable,
    };

    const transpiler_params_ = [_]ParamType{
        clap.parseParam("--main-fields <STR>...             Main fields to lookup in package.json. Defaults to --target dependent") catch unreachable,
        clap.parseParam("--preserve-symlinks               Preserve symlinks when resolving files") catch unreachable,
        clap.parseParam("--preserve-symlinks-main          Preserve symlinks when resolving the main entry point") catch unreachable,
        clap.parseParam("--extension-order <STR>...        Defaults to: .tsx,.ts,.jsx,.js,.json ") catch unreachable,
        clap.parseParam("--tsconfig-override <STR>          Specify custom tsconfig.json. Default <d>$cwd<r>/tsconfig.json") catch unreachable,
        clap.parseParam("-d, --define <STR>...              Substitute K:V while parsing, e.g. --define process.env.NODE_ENV:\"development\". Values are parsed as JSON.") catch unreachable,
        clap.parseParam("--drop <STR>...                   Remove function calls, e.g. --drop=console removes all console.* calls.") catch unreachable,
        clap.parseParam("-l, --loader <STR>...             Parse files with .ext:loader, e.g. --loader .js:jsx. Valid loaders: js, jsx, ts, tsx, json, toml, text, file, wasm, napi") catch unreachable,
        clap.parseParam("--no-macros                       Disable macros from being executed in the bundler, transpiler and runtime") catch unreachable,
        clap.parseParam("--jsx-factory <STR>               Changes the function called when compiling JSX elements using the classic JSX runtime") catch unreachable,
        clap.parseParam("--jsx-fragment <STR>              Changes the function called when compiling JSX fragments") catch unreachable,
        clap.parseParam("--jsx-import-source <STR>         Declares the module specifier to be used for importing the jsx and jsxs factory functions. Default: \"react\"") catch unreachable,
        clap.parseParam("--jsx-runtime <STR>               \"automatic\" (default) or \"classic\"") catch unreachable,
        clap.parseParam("--ignore-dce-annotations          Ignore tree-shaking annotations such as @__PURE__") catch unreachable,
    };
    const runtime_params_ = [_]ParamType{
        clap.parseParam("--watch                           Automatically restart the process on file change") catch unreachable,
        clap.parseParam("--hot                             Enable auto reload in the Bun runtime, test runner, or bundler") catch unreachable,
        clap.parseParam("--no-clear-screen                 Disable clearing the terminal screen on reload when --hot or --watch is enabled") catch unreachable,
        clap.parseParam("--smol                            Use less memory, but run garbage collection more often") catch unreachable,
        clap.parseParam("-r, --preload <STR>...            Import a module before other modules are loaded") catch unreachable,
        clap.parseParam("--require <STR>...                Alias of --preload, for Node.js compatibility") catch unreachable,
        clap.parseParam("--inspect <STR>?                  Activate Bun's debugger") catch unreachable,
        clap.parseParam("--inspect-wait <STR>?             Activate Bun's debugger, wait for a connection before executing") catch unreachable,
        clap.parseParam("--inspect-brk <STR>?              Activate Bun's debugger, set breakpoint on first line of code and wait") catch unreachable,
        clap.parseParam("--if-present                      Exit without an error if the entrypoint does not exist") catch unreachable,
        clap.parseParam("--no-install                      Disable auto install in the Bun runtime") catch unreachable,
        clap.parseParam("--install <STR>                   Configure auto-install behavior. One of \"auto\" (default, auto-installs when no node_modules), \"fallback\" (missing packages only), \"force\" (always).") catch unreachable,
        clap.parseParam("-i                                Auto-install dependencies during execution. Equivalent to --install=fallback.") catch unreachable,
        clap.parseParam("-e, --eval <STR>                  Evaluate argument as a script") catch unreachable,
        clap.parseParam("-p, --print <STR>                 Evaluate argument as a script and print the result") catch unreachable,
        clap.parseParam("--prefer-offline                  Skip staleness checks for packages in the Bun runtime and resolve from disk") catch unreachable,
        clap.parseParam("--prefer-latest                   Use the latest matching versions of packages in the Bun runtime, always checking npm") catch unreachable,
        clap.parseParam("--port <STR>                      Set the default port for Bun.serve") catch unreachable,
        clap.parseParam("-u, --origin <STR>") catch unreachable,
        clap.parseParam("--conditions <STR>...             Pass custom conditions to resolve") catch unreachable,
        clap.parseParam("--fetch-preconnect <STR>...       Preconnect to a URL while code is loading") catch unreachable,
        clap.parseParam("--max-http-header-size <INT>      Set the maximum size of HTTP headers in bytes. Default is 16KiB") catch unreachable,
        clap.parseParam("--dns-result-order <STR>          Set the default order of DNS lookup results. Valid orders: verbatim (default), ipv4first, ipv6first") catch unreachable,
        clap.parseParam("--expose-gc                       Expose gc() on the global object. Has no effect on Bun.gc().") catch unreachable,
        clap.parseParam("--no-deprecation                  Suppress all reporting of the custom deprecation.") catch unreachable,
        clap.parseParam("--throw-deprecation               Determine whether or not deprecation warnings result in errors.") catch unreachable,
        clap.parseParam("--title <STR>                     Set the process title") catch unreachable,
        clap.parseParam("--zero-fill-buffers                Boolean to force Buffer.allocUnsafe(size) to be zero-filled.") catch unreachable,
        clap.parseParam("--redis-preconnect                Preconnect to $REDIS_URL at startup") catch unreachable,
        clap.parseParam("--no-addons                       Throw an error if process.dlopen is called, and disable export condition \"node-addons\"") catch unreachable,
    };

    const auto_or_run_params = [_]ParamType{
        clap.parseParam("-F, --filter <STR>...             Run a script in all workspace packages matching the pattern") catch unreachable,
        clap.parseParam("-b, --bun                         Force a script or package to use Bun's runtime instead of Node.js (via symlinking node)") catch unreachable,
        clap.parseParam("--shell <STR>                     Control the shell used for package.json scripts. Supports either 'bun' or 'system'") catch unreachable,
    };

    const auto_only_params = [_]ParamType{
        // clap.parseParam("--all") catch unreachable,
        clap.parseParam("--silent                          Don't print the script command") catch unreachable,
        clap.parseParam("--elide-lines <NUMBER>            Number of lines of script output shown when using --filter (default: 10). Set to 0 to show all lines.") catch unreachable,
        clap.parseParam("-v, --version                     Print version and exit") catch unreachable,
        clap.parseParam("--revision                        Print version with revision and exit") catch unreachable,
    } ++ auto_or_run_params;
    pub const auto_params = auto_only_params ++ runtime_params_ ++ transpiler_params_ ++ base_params_;

    const run_only_params = [_]ParamType{
        clap.parseParam("--silent                          Don't print the script command") catch unreachable,
        clap.parseParam("--elide-lines <NUMBER>            Number of lines of script output shown when using --filter (default: 10). Set to 0 to show all lines.") catch unreachable,
    } ++ auto_or_run_params;
    pub const run_params = run_only_params ++ runtime_params_ ++ transpiler_params_ ++ base_params_;

    const bunx_commands = [_]ParamType{
        clap.parseParam("-b, --bun                         Force a script or package to use Bun's runtime instead of Node.js (via symlinking node)") catch unreachable,
    } ++ auto_only_params;

    const build_only_params = [_]ParamType{
        clap.parseParam("--production                     Set NODE_ENV=production and enable minification") catch unreachable,
        clap.parseParam("--compile                        Generate a standalone Bun executable containing your bundled code. Implies --production") catch unreachable,
        clap.parseParam("--bytecode                       Use a bytecode cache") catch unreachable,
        clap.parseParam("--watch                          Automatically restart the process on file change") catch unreachable,
        clap.parseParam("--no-clear-screen                Disable clearing the terminal screen on reload when --watch is enabled") catch unreachable,
        clap.parseParam("--target <STR>                   The intended execution environment for the bundle. \"browser\", \"bun\" or \"node\"") catch unreachable,
        clap.parseParam("--outdir <STR>                   Default to \"dist\" if multiple files") catch unreachable,
        clap.parseParam("--outfile <STR>                  Write to a file") catch unreachable,
        clap.parseParam("--sourcemap <STR>?               Build with sourcemaps - 'linked', 'inline', 'external', or 'none'") catch unreachable,
        clap.parseParam("--banner <STR>                   Add a banner to the bundled output such as \"use client\"; for a bundle being used with RSCs") catch unreachable,
        clap.parseParam("--footer <STR>                   Add a footer to the bundled output such as // built with bun!") catch unreachable,
        clap.parseParam("--format <STR>                   Specifies the module format to build to. \"esm\", \"cjs\" and \"iife\" are supported. Defaults to \"esm\".") catch unreachable,
        clap.parseParam("--root <STR>                     Root directory used for multiple entry points") catch unreachable,
        clap.parseParam("--splitting                      Enable code splitting") catch unreachable,
        clap.parseParam("--public-path <STR>              A prefix to be appended to any import paths in bundled code") catch unreachable,
        clap.parseParam("-e, --external <STR>...          Exclude module from transpilation (can use * wildcards). ex: -e react") catch unreachable,
        clap.parseParam("--packages <STR>                 Add dependencies to bundle or keep them external. \"external\", \"bundle\" is supported. Defaults to \"bundle\".") catch unreachable,
        clap.parseParam("--entry-naming <STR>             Customize entry point filenames. Defaults to \"[dir]/[name].[ext]\"") catch unreachable,
        clap.parseParam("--chunk-naming <STR>             Customize chunk filenames. Defaults to \"[name]-[hash].[ext]\"") catch unreachable,
        clap.parseParam("--asset-naming <STR>             Customize asset filenames. Defaults to \"[name]-[hash].[ext]\"") catch unreachable,
        clap.parseParam("--react-fast-refresh             Enable React Fast Refresh transform (does not emit hot-module code, use this for testing)") catch unreachable,
        clap.parseParam("--no-bundle                      Transpile file only, do not bundle") catch unreachable,
        clap.parseParam("--emit-dce-annotations           Re-emit DCE annotations in bundles. Enabled by default unless --minify-whitespace is passed.") catch unreachable,
        clap.parseParam("--minify                         Enable all minification flags") catch unreachable,
        clap.parseParam("--minify-syntax                  Minify syntax and inline data") catch unreachable,
        clap.parseParam("--minify-whitespace              Minify whitespace") catch unreachable,
        clap.parseParam("--minify-identifiers             Minify identifiers") catch unreachable,
        clap.parseParam("--css-chunking                   Chunk CSS files together to reduce duplicated CSS loaded in a browser. Only has an effect when multiple entrypoints import CSS") catch unreachable,
        clap.parseParam("--dump-environment-variables") catch unreachable,
        clap.parseParam("--conditions <STR>...            Pass custom conditions to resolve") catch unreachable,
        clap.parseParam("--app                            (EXPERIMENTAL) Build a web app for production using Bun Bake.") catch unreachable,
        clap.parseParam("--server-components              (EXPERIMENTAL) Enable server components") catch unreachable,
        clap.parseParam("--env <inline|prefix*|disable>   Inline environment variables into the bundle as process.env.${name}. Defaults to 'disable'. To inline environment variables matching a prefix, use my prefix like 'FOO_PUBLIC_*'.") catch unreachable,
        clap.parseParam("--windows-hide-console           When using --compile targeting Windows, prevent a Command prompt from opening alongside the executable") catch unreachable,
        clap.parseParam("--windows-icon <STR>             When using --compile targeting Windows, assign an executable icon") catch unreachable,
    } ++ if (FeatureFlags.bake_debugging_features) [_]ParamType{
        clap.parseParam("--debug-dump-server-files        When --app is set, dump all server files to disk even when building statically") catch unreachable,
        clap.parseParam("--debug-no-minify                When --app is set, do not minify anything") catch unreachable,
    } else .{};
    pub const build_params = build_only_params ++ transpiler_params_ ++ base_params_;

    // TODO: update test completions
    const test_only_params = [_]ParamType{
        clap.parseParam("--timeout <NUMBER>               Set the per-test timeout in milliseconds, default is 5000.") catch unreachable,
        clap.parseParam("-u, --update-snapshots           Update snapshot files") catch unreachable,
        clap.parseParam("--rerun-each <NUMBER>            Re-run each test file <NUMBER> times, helps catch certain bugs") catch unreachable,
        clap.parseParam("--only                           Only run tests that are marked with \"test.only()\"") catch unreachable,
        clap.parseParam("--todo                           Include tests that are marked with \"test.todo()\"") catch unreachable,
        clap.parseParam("--coverage                       Generate a coverage profile") catch unreachable,
        clap.parseParam("--coverage-reporter <STR>...     Report coverage in 'text' and/or 'lcov'. Defaults to 'text'.") catch unreachable,
        clap.parseParam("--coverage-dir <STR>             Directory for coverage files. Defaults to 'coverage'.") catch unreachable,
        clap.parseParam("--bail <NUMBER>?                 Exit the test suite after <NUMBER> failures. If you do not specify a number, it defaults to 1.") catch unreachable,
        clap.parseParam("-t, --test-name-pattern <STR>    Run only tests with a name that matches the given regex.") catch unreachable,
        clap.parseParam("--reporter <STR>                 Specify the test reporter. Currently --reporter=junit is the only supported format.") catch unreachable,
        clap.parseParam("--reporter-outfile <STR>         The output file used for the format from --reporter.") catch unreachable,
    };
    pub const test_params = test_only_params ++ runtime_params_ ++ transpiler_params_ ++ base_params_;

    pub fn loadConfigPath(allocator: std.mem.Allocator, auto_loaded: bool, config_path: [:0]const u8, ctx: Command.Context, comptime cmd: Command.Tag) !void {
        var config_file = switch (bun.sys.openA(config_path, bun.O.RDONLY, 0)) {
            .result => |fd| fd.stdFile(),
            .err => |err| {
                if (auto_loaded) return;
                Output.prettyErrorln("{}\nwhile opening config \"{s}\"", .{
                    err,
                    config_path,
                });
                Global.exit(1);
            },
        };

        defer config_file.close();
        const contents = config_file.readToEndAlloc(allocator, std.math.maxInt(usize)) catch |err| {
            if (auto_loaded) return;
            Output.prettyErrorln("<r><red>error<r>: {s} reading config \"{s}\"", .{
                @errorName(err),
                config_path,
            });
            Global.exit(1);
        };

        js_ast.Stmt.Data.Store.create();
        js_ast.Expr.Data.Store.create();
        defer {
            js_ast.Stmt.Data.Store.reset();
            js_ast.Expr.Data.Store.reset();
        }
        const original_level = ctx.log.level;
        defer {
            ctx.log.level = original_level;
        }
        ctx.log.level = logger.Log.Level.warn;
        try Bunfig.parse(allocator, &logger.Source.initPathString(bun.asByteSlice(config_path), contents), ctx, cmd);
    }

    fn getHomeConfigPath(buf: *bun.PathBuffer) ?[:0]const u8 {
        if (bun.getenvZ("XDG_CONFIG_HOME") orelse bun.getenvZ(bun.DotEnv.home_env)) |data_dir| {
            var paths = [_]string{".bunfig.toml"};
            return resolve_path.joinAbsStringBufZ(data_dir, buf, &paths, .auto);
        }

        return null;
    }
    pub fn loadConfig(allocator: std.mem.Allocator, user_config_path_: ?string, ctx: Command.Context, comptime cmd: Command.Tag) OOM!void {
        var config_buf: bun.PathBuffer = undefined;
        if (comptime cmd.readGlobalConfig()) {
            if (!ctx.has_loaded_global_config) {
                ctx.has_loaded_global_config = true;

                if (getHomeConfigPath(&config_buf)) |path| {
                    loadConfigPath(allocator, true, path, ctx, comptime cmd) catch |err| {
                        if (ctx.log.hasAny()) {
                            ctx.log.print(Output.errorWriter()) catch {};
                        }
                        if (ctx.log.hasAny()) Output.printError("\n", .{});
                        Output.err(err, "failed to load bunfig", .{});
                        Global.crash();
                    };
                }
            }
        }

        var config_path_: []const u8 = user_config_path_ orelse "";

        var auto_loaded: bool = false;
        if (config_path_.len == 0 and (user_config_path_ != null or
            Command.Tag.always_loads_config.get(cmd) or
            (cmd == .AutoCommand and
                // "bun"
                (ctx.positionals.len == 0 or
                    // "bun file.js"
                    ctx.positionals.len > 0 and options.defaultLoaders.has(std.fs.path.extension(ctx.positionals[0]))))))
        {
            config_path_ = "bunfig.toml";
            auto_loaded = true;
        }

        if (config_path_.len == 0) {
            return;
        }
        defer ctx.debug.loaded_bunfig = true;
        var config_path: [:0]u8 = undefined;
        if (config_path_[0] == '/') {
            @memcpy(config_buf[0..config_path_.len], config_path_);
            config_buf[config_path_.len] = 0;
            config_path = config_buf[0..config_path_.len :0];
        } else {
            if (ctx.args.absolute_working_dir == null) {
                var secondbuf: bun.PathBuffer = undefined;
                const cwd = bun.getcwd(&secondbuf) catch return;

                ctx.args.absolute_working_dir = try allocator.dupeZ(u8, cwd);
            }

            var parts = [_]string{ ctx.args.absolute_working_dir.?, config_path_ };
            config_path_ = resolve_path.joinAbsStringBuf(
                ctx.args.absolute_working_dir.?,
                &config_buf,
                &parts,
                .auto,
            );
            config_buf[config_path_.len] = 0;
            config_path = config_buf[0..config_path_.len :0];
        }

        loadConfigPath(allocator, auto_loaded, config_path, ctx, comptime cmd) catch |err| {
            if (ctx.log.hasAny()) {
                ctx.log.print(Output.errorWriter()) catch {};
            }
            if (ctx.log.hasAny()) Output.printError("\n", .{});
            Output.err(err, "failed to load bunfig", .{});
            Global.crash();
        };
    }

    pub fn loadConfigWithCmdArgs(
        comptime cmd: Command.Tag,
        allocator: std.mem.Allocator,
        args: clap.Args(clap.Help, cmd.params()),
        ctx: Command.Context,
    ) OOM!void {
        return try loadConfig(allocator, args.option("--config"), ctx, comptime cmd);
    }

    pub fn parse(allocator: std.mem.Allocator, ctx: Command.Context, comptime cmd: Command.Tag) !Api.TransformOptions {
        var diag = clap.Diagnostic{};
        const params_to_parse = comptime cmd.params();

        var args = clap.parse(clap.Help, params_to_parse, .{
            .diagnostic = &diag,
            .allocator = allocator,
            .stop_after_positional_at = switch (cmd) {
                .RunCommand => 2,
                .AutoCommand, .RunAsNodeCommand => 1,
                else => 0,
            },
        }) catch |err| {
            // Report useful error and exit
            diag.report(Output.errorWriter(), err) catch {};
            cmd.printHelp(false);
            Global.exit(1);
        };

        const print_help = args.flag("--help");
        if (print_help) {
            cmd.printHelp(true);
            Output.flush();
            Global.exit(0);
        }

        if (cmd == .AutoCommand) {
            if (args.flag("--version")) {
                printVersionAndExit();
            }

            if (args.flag("--revision")) {
                printRevisionAndExit();
            }
        }

        if (builtin.have_error_return_tracing) {
            if (args.flag("--verbose-error-trace")) {
                bun.crash_handler.verbose_error_trace = true;
            }
        }

        var cwd: [:0]u8 = undefined;
        if (args.option("--cwd")) |cwd_arg| {
            cwd = brk: {
                var outbuf: bun.PathBuffer = undefined;
                const out = bun.path.joinAbs(try bun.getcwd(&outbuf), .loose, cwd_arg);
                bun.sys.chdir("", out).unwrap() catch |err| {
                    Output.err(err, "Could not change directory to \"{s}\"\n", .{cwd_arg});
                    Global.exit(1);
                };
                break :brk try allocator.dupeZ(u8, out);
            };
        } else {
            cwd = try bun.getcwdAlloc(allocator);
        }

        if (cmd == .RunCommand or cmd == .AutoCommand) {
            ctx.filters = args.options("--filter");

            if (args.option("--elide-lines")) |elide_lines| {
                if (elide_lines.len > 0) {
                    ctx.bundler_options.elide_lines = std.fmt.parseInt(usize, elide_lines, 10) catch {
                        Output.prettyErrorln("<r><red>error<r>: Invalid elide-lines: \"{s}\"", .{elide_lines});
                        Global.exit(1);
                    };
                }
            }
        }

        if (cmd == .TestCommand) {
            if (args.option("--timeout")) |timeout_ms| {
                if (timeout_ms.len > 0) {
                    ctx.test_options.default_timeout_ms = std.fmt.parseInt(u32, timeout_ms, 10) catch {
                        Output.prettyErrorln("<r><red>error<r>: Invalid timeout: \"{s}\"", .{timeout_ms});
                        Global.exit(1);
                    };
                }
            }

            if (!ctx.test_options.coverage.enabled) {
                ctx.test_options.coverage.enabled = args.flag("--coverage");
            }

            if (args.options("--coverage-reporter").len > 0) {
                ctx.test_options.coverage.reporters = .{ .text = false, .lcov = false };
                for (args.options("--coverage-reporter")) |reporter| {
                    if (bun.strings.eqlComptime(reporter, "text")) {
                        ctx.test_options.coverage.reporters.text = true;
                    } else if (bun.strings.eqlComptime(reporter, "lcov")) {
                        ctx.test_options.coverage.reporters.lcov = true;
                    } else {
                        Output.prettyErrorln("<r><red>error<r>: --coverage-reporter received invalid reporter: \"{s}\"", .{reporter});
                        Global.exit(1);
                    }
                }
            }

            if (args.option("--reporter-outfile")) |reporter_outfile| {
                ctx.test_options.reporter_outfile = reporter_outfile;
            }

            if (args.option("--reporter")) |reporter| {
                if (strings.eqlComptime(reporter, "junit")) {
                    if (ctx.test_options.reporter_outfile == null) {
                        Output.errGeneric("--reporter=junit expects an output file from --reporter-outfile", .{});
                        Global.crash();
                    }
                    ctx.test_options.file_reporter = .junit;
                } else {
                    Output.errGeneric("unrecognized reporter format: '{s}'. Currently, only 'junit' is supported", .{reporter});
                    Global.crash();
                }
            }

            if (args.option("--coverage-dir")) |dir| {
                ctx.test_options.coverage.reports_directory = dir;
            }

            if (args.option("--bail")) |bail| {
                if (bail.len > 0) {
                    ctx.test_options.bail = std.fmt.parseInt(u32, bail, 10) catch |e| {
                        Output.prettyErrorln("<r><red>error<r>: --bail expects a number: {s}", .{@errorName(e)});
                        Global.exit(1);
                    };

                    if (ctx.test_options.bail == 0) {
                        Output.prettyErrorln("<r><red>error<r>: --bail expects a number greater than 0", .{});
                        Global.exit(1);
                    }
                } else {
                    ctx.test_options.bail = 1;
                }
            }
            if (args.option("--rerun-each")) |repeat_count| {
                if (repeat_count.len > 0) {
                    ctx.test_options.repeat_count = std.fmt.parseInt(u32, repeat_count, 10) catch |e| {
                        Output.prettyErrorln("<r><red>error<r>: --rerun-each expects a number: {s}", .{@errorName(e)});
                        Global.exit(1);
                    };
                }
            }
            if (args.option("--test-name-pattern")) |namePattern| {
                const regex = RegularExpression.init(bun.String.fromBytes(namePattern), RegularExpression.Flags.none) catch {
                    Output.prettyErrorln(
                        "<r><red>error<r>: --test-name-pattern expects a valid regular expression but received {}",
                        .{
                            bun.fmt.QuotedFormatter{
                                .text = namePattern,
                            },
                        },
                    );
                    Global.exit(1);
                };
                ctx.test_options.test_filter_regex = regex;
            }
            ctx.test_options.update_snapshots = args.flag("--update-snapshots");
            ctx.test_options.run_todo = args.flag("--todo");
            ctx.test_options.only = args.flag("--only");
        }

        ctx.args.absolute_working_dir = cwd;
        ctx.positionals = args.positionals();

        if (comptime Command.Tag.loads_config.get(cmd)) {
            try loadConfigWithCmdArgs(cmd, allocator, args, ctx);
        }

        var opts: Api.TransformOptions = ctx.args;

        const defines_tuple = try DefineColonList.resolve(allocator, args.options("--define"));

        if (defines_tuple.keys.len > 0) {
            opts.define = .{
                .keys = defines_tuple.keys,
                .values = defines_tuple.values,
            };
        }

        opts.drop = args.options("--drop");

        // Node added a `--loader` flag (that's kinda like `--register`). It's
        // completely different from ours.
        const loader_tuple = if (cmd != .RunAsNodeCommand)
            try LoaderColonList.resolve(allocator, args.options("--loader"))
        else
            .{ .keys = &[_]u8{}, .values = &[_]Api.Loader{} };

        if (loader_tuple.keys.len > 0) {
            opts.loaders = .{
                .extensions = loader_tuple.keys,
                .loaders = loader_tuple.values,
            };
        }

        opts.tsconfig_override = if (args.option("--tsconfig-override")) |ts|
            (Arguments.readFile(allocator, cwd, ts) catch |err| fileReadError(err, Output.errorStream(), ts, "tsconfig.json"))
        else
            null;

        opts.main_fields = args.options("--main-fields");
        // we never actually supported inject.
        // opts.inject = args.options("--inject");
        opts.env_files = args.options("--env-file");
        opts.extension_order = args.options("--extension-order");

        if (args.flag("--preserve-symlinks")) {
            opts.preserve_symlinks = true;
        }
        if (args.flag("--preserve-symlinks-main")) {
            ctx.runtime_options.preserve_symlinks_main = true;
        }

        ctx.passthrough = args.remaining();

        if (cmd == .AutoCommand or cmd == .RunCommand or cmd == .BuildCommand or cmd == .TestCommand) {
            if (args.options("--conditions").len > 0) {
                opts.conditions = args.options("--conditions");
            }
        }

        // runtime commands
        if (cmd == .AutoCommand or cmd == .RunCommand or cmd == .TestCommand or cmd == .RunAsNodeCommand) {
            var preloads = args.options("--preload");
            if (preloads.len == 0) {
                if (bun.getenvZ("BUN_INSPECT_PRELOAD")) |preload| {
                    preloads = bun.default_allocator.dupe([]const u8, &.{preload}) catch unreachable;
                }
            }
            const preloads2 = args.options("--require");

            if (args.flag("--hot")) {
                ctx.debug.hot_reload = .hot;
                if (args.flag("--no-clear-screen")) {
                    bun.DotEnv.Loader.has_no_clear_screen_cli_flag = true;
                }
            } else if (args.flag("--watch")) {
                ctx.debug.hot_reload = .watch;

                // Windows applies this to the watcher child process.
                // The parent process is unable to re-launch itself
                if (!bun.Environment.isWindows)
                    bun.auto_reload_on_crash = true;

                if (args.flag("--no-clear-screen")) {
                    bun.DotEnv.Loader.has_no_clear_screen_cli_flag = true;
                }
            }

            if (args.option("--origin")) |origin| {
                opts.origin = origin;
            }

            if (args.flag("--redis-preconnect")) {
                ctx.runtime_options.redis_preconnect = true;
            }

            if (args.flag("--no-addons")) {
                // used for disabling process.dlopen and
                // for disabling export condition "node-addons"
                opts.allow_addons = false;
            }

            if (args.option("--port")) |port_str| {
                if (comptime cmd == .RunAsNodeCommand) {
                    // TODO: prevent `node --port <script>` from working
                    ctx.runtime_options.eval.script = port_str;
                    ctx.runtime_options.eval.eval_and_print = true;
                } else {
                    opts.port = std.fmt.parseInt(u16, port_str, 10) catch {
                        Output.errFmt(
                            bun.fmt.outOfRange(port_str, .{
                                .field_name = "--port",
                                .min = 0,
                                .max = std.math.maxInt(u16),
                            }),
                        );
                        Output.note("To evaluate TypeScript here, use 'bun --print'", .{});
                        Global.exit(1);
                    };
                }
            }

            if (args.option("--max-http-header-size")) |size_str| {
                const size = std.fmt.parseInt(usize, size_str, 10) catch {
                    Output.errGeneric("Invalid value for --max-http-header-size: \"{s}\". Must be a positive integer\n", .{size_str});
                    Global.exit(1);
                };
                if (size == 0) {
                    bun.http.max_http_header_size = 1024 * 1024 * 1024;
                } else {
                    bun.http.max_http_header_size = size;
                }
            }

            ctx.debug.offline_mode_setting = if (args.flag("--prefer-offline"))
                Bunfig.OfflineMode.offline
            else if (args.flag("--prefer-latest"))
                Bunfig.OfflineMode.latest
            else
                Bunfig.OfflineMode.online;

            if (args.flag("--no-install")) {
                ctx.debug.global_cache = .disable;
            } else if (args.flag("-i")) {
                ctx.debug.global_cache = .fallback;
            } else if (args.option("--install")) |enum_value| {
                // -i=auto --install=force, --install=disable
                if (options.GlobalCache.Map.get(enum_value)) |result| {
                    ctx.debug.global_cache = result;
                    // -i, --install
                } else if (enum_value.len == 0) {
                    ctx.debug.global_cache = options.GlobalCache.force;
                } else {
                    Output.errGeneric("Invalid value for --install: \"{s}\". Must be either \"auto\", \"fallback\", \"force\", or \"disable\"\n", .{enum_value});
                    Global.exit(1);
                }
            }

            if (ctx.preloads.len > 0 and (preloads.len > 0 or preloads2.len > 0)) {
                var all = std.ArrayList(string).initCapacity(ctx.allocator, ctx.preloads.len + preloads.len + preloads2.len) catch unreachable;
                all.appendSliceAssumeCapacity(ctx.preloads);
                all.appendSliceAssumeCapacity(preloads);
                all.appendSliceAssumeCapacity(preloads2);
                ctx.preloads = all.items;
            } else if (preloads.len > 0) {
                if (preloads2.len > 0) {
                    var all = std.ArrayList(string).initCapacity(ctx.allocator, preloads.len + preloads2.len) catch unreachable;
                    all.appendSliceAssumeCapacity(preloads);
                    all.appendSliceAssumeCapacity(preloads2);
                    ctx.preloads = all.items;
                } else {
                    ctx.preloads = preloads;
                }
            } else if (preloads2.len > 0) {
                ctx.preloads = preloads2;
            }

            if (args.option("--print")) |script| {
                ctx.runtime_options.eval.script = script;
                ctx.runtime_options.eval.eval_and_print = true;
            } else if (args.option("--eval")) |script| {
                ctx.runtime_options.eval.script = script;
            }
            ctx.runtime_options.if_present = args.flag("--if-present");
            ctx.runtime_options.smol = args.flag("--smol");
            ctx.runtime_options.preconnect = args.options("--fetch-preconnect");
            ctx.runtime_options.expose_gc = args.flag("--expose-gc");

            if (args.option("--dns-result-order")) |order| {
                ctx.runtime_options.dns_result_order = order;
            }

            if (args.option("--inspect")) |inspect_flag| {
                ctx.runtime_options.debugger = if (inspect_flag.len == 0)
                    Command.Debugger{ .enable = .{} }
                else
                    Command.Debugger{ .enable = .{
                        .path_or_port = inspect_flag,
                    } };

                bun.JSC.RuntimeTranspilerCache.is_disabled = true;
            } else if (args.option("--inspect-wait")) |inspect_flag| {
                ctx.runtime_options.debugger = if (inspect_flag.len == 0)
                    Command.Debugger{ .enable = .{
                        .wait_for_connection = true,
                    } }
                else
                    Command.Debugger{ .enable = .{
                        .path_or_port = inspect_flag,
                        .wait_for_connection = true,
                    } };

                bun.JSC.RuntimeTranspilerCache.is_disabled = true;
            } else if (args.option("--inspect-brk")) |inspect_flag| {
                ctx.runtime_options.debugger = if (inspect_flag.len == 0)
                    Command.Debugger{ .enable = .{
                        .wait_for_connection = true,
                        .set_breakpoint_on_first_line = true,
                    } }
                else
                    Command.Debugger{ .enable = .{
                        .path_or_port = inspect_flag,
                        .wait_for_connection = true,
                        .set_breakpoint_on_first_line = true,
                    } };

                bun.JSC.RuntimeTranspilerCache.is_disabled = true;
            }

            if (args.flag("--no-deprecation")) {
                Bun__Node__ProcessNoDeprecation = true;
            }
            if (args.flag("--throw-deprecation")) {
                Bun__Node__ProcessThrowDeprecation = true;
            }
            if (args.option("--title")) |title| {
                Bun__Node__ProcessTitle = title;
            }
            if (args.flag("--zero-fill-buffers")) {
                Bun__Node__ZeroFillBuffers = true;
            }
        }

        if (opts.port != null and opts.origin == null) {
            opts.origin = try std.fmt.allocPrint(allocator, "http://localhost:{d}/", .{opts.port.?});
        }

        const output_dir: ?string = null;
        const output_file: ?string = null;

        ctx.bundler_options.ignore_dce_annotations = args.flag("--ignore-dce-annotations");

        if (cmd == .BuildCommand) {
            ctx.bundler_options.transform_only = args.flag("--no-bundle");
            ctx.bundler_options.bytecode = args.flag("--bytecode");

            const production = args.flag("--production");

            if (args.flag("--app")) {
                if (!bun.FeatureFlags.bake()) {
                    Output.errGeneric("To use the experimental \"--app\" option, upgrade to the canary build of bun via \"bun upgrade --canary\"", .{});
                    Global.crash();
                }

                ctx.bundler_options.bake = true;
                ctx.bundler_options.bake_debug_dump_server = bun.FeatureFlags.bake_debugging_features and
                    args.flag("--debug-dump-server-files");
                ctx.bundler_options.bake_debug_disable_minify = bun.FeatureFlags.bake_debugging_features and
                    args.flag("--debug-no-minify");
            }

            // TODO: support --format=esm
            if (ctx.bundler_options.bytecode) {
                ctx.bundler_options.output_format = .cjs;
                ctx.args.target = .bun;
            }

            if (args.option("--public-path")) |public_path| {
                ctx.bundler_options.public_path = public_path;
            }

            if (args.option("--banner")) |banner| {
                ctx.bundler_options.banner = banner;
            }

            if (args.option("--footer")) |footer| {
                ctx.bundler_options.footer = footer;
            }

            const minify_flag = args.flag("--minify") or production;
            ctx.bundler_options.minify_syntax = minify_flag or args.flag("--minify-syntax");
            ctx.bundler_options.minify_whitespace = minify_flag or args.flag("--minify-whitespace");
            ctx.bundler_options.minify_identifiers = minify_flag or args.flag("--minify-identifiers");

            ctx.bundler_options.css_chunking = args.flag("--css-chunking");

            ctx.bundler_options.emit_dce_annotations = args.flag("--emit-dce-annotations") or
                !ctx.bundler_options.minify_whitespace;

            if (args.options("--external").len > 0) {
                var externals = try allocator.alloc([]const u8, args.options("--external").len);
                for (args.options("--external"), 0..) |external, i| {
                    externals[i] = external;
                }
                opts.external = externals;
            }

            if (args.option("--packages")) |packages| {
                if (strings.eqlComptime(packages, "bundle")) {
                    opts.packages = .bundle;
                } else if (strings.eqlComptime(packages, "external")) {
                    opts.packages = .external;
                } else {
                    Output.prettyErrorln("<r><red>error<r>: Invalid packages setting: \"{s}\"", .{packages});
                    Global.crash();
                }
            }

            if (args.option("--env")) |env| {
                if (strings.indexOfChar(env, '*')) |asterisk| {
                    if (asterisk == 0) {
                        ctx.bundler_options.env_behavior = .load_all;
                    } else {
                        ctx.bundler_options.env_behavior = .prefix;
                        ctx.bundler_options.env_prefix = env[0..asterisk];
                    }
                } else if (strings.eqlComptime(env, "inline") or strings.eqlComptime(env, "1")) {
                    ctx.bundler_options.env_behavior = .load_all;
                } else if (strings.eqlComptime(env, "disable") or strings.eqlComptime(env, "0")) {
                    ctx.bundler_options.env_behavior = .load_all_without_inlining;
                } else {
                    Output.prettyErrorln("<r><red>error<r>: Expected 'env' to be 'inline', 'disable', or a prefix with a '*' character", .{});
                    Global.crash();
                }
            }

            const TargetMatcher = strings.ExactSizeMatcher(8);
            if (args.option("--target")) |_target| brk: {
                if (comptime cmd == .BuildCommand) {
                    if (args.flag("--compile")) {
                        if (_target.len > 4 and strings.hasPrefixComptime(_target, "bun-")) {
                            ctx.bundler_options.compile_target = Cli.CompileTarget.from(_target[3..]);
                            if (!ctx.bundler_options.compile_target.isSupported()) {
                                Output.errGeneric("Unsupported compile target: {}\n", .{ctx.bundler_options.compile_target});
                                Global.exit(1);
                            }
                            opts.target = .bun;
                            break :brk;
                        }
                    }
                }

                opts.target = opts.target orelse switch (TargetMatcher.match(_target)) {
                    TargetMatcher.case("browser") => Api.Target.browser,
                    TargetMatcher.case("node") => Api.Target.node,
                    TargetMatcher.case("macro") => if (cmd == .BuildCommand) Api.Target.bun_macro else Api.Target.bun,
                    TargetMatcher.case("bun") => Api.Target.bun,
                    else => invalidTarget(&diag, _target),
                };

                if (opts.target.? == .bun) {
                    ctx.debug.run_in_bun = opts.target.? == .bun;
                } else {
                    if (ctx.bundler_options.bytecode) {
                        Output.errGeneric("target must be 'bun' when bytecode is true. Received: {s}", .{@tagName(opts.target.?)});
                        Global.exit(1);
                    }

                    if (ctx.bundler_options.bake) {
                        Output.errGeneric("target must be 'bun' when using --app. Received: {s}", .{@tagName(opts.target.?)});
                    }
                }
            }

            if (args.flag("--watch")) {
                ctx.debug.hot_reload = .watch;
                bun.auto_reload_on_crash = true;

                if (args.flag("--no-clear-screen")) {
                    bun.DotEnv.Loader.has_no_clear_screen_cli_flag = true;
                }
            }

            if (args.flag("--compile")) {
                ctx.bundler_options.compile = true;
                ctx.bundler_options.inline_entrypoint_import_meta_main = true;
            }

            if (args.flag("--windows-hide-console")) {
                // --windows-hide-console technically doesnt depend on WinAPI, but since since --windows-icon
                // does, all of these customization options have been gated to windows-only
                if (!Environment.isWindows) {
                    Output.errGeneric("Using --windows-hide-console is only available when compiling on Windows", .{});
                    Global.crash();
                }
                if (!ctx.bundler_options.compile) {
                    Output.errGeneric("--windows-hide-console requires --compile", .{});
                    Global.crash();
                }
                ctx.bundler_options.windows_hide_console = true;
            }
            if (args.option("--windows-icon")) |path| {
                if (!Environment.isWindows) {
                    Output.errGeneric("Using --windows-icon is only available when compiling on Windows", .{});
                    Global.crash();
                }
                if (!ctx.bundler_options.compile) {
                    Output.errGeneric("--windows-icon requires --compile", .{});
                    Global.crash();
                }
                ctx.bundler_options.windows_icon = path;
            }

            if (args.option("--outdir")) |outdir| {
                if (outdir.len > 0) {
                    ctx.bundler_options.outdir = outdir;
                }
            } else if (args.option("--outfile")) |outfile| {
                if (outfile.len > 0) {
                    ctx.bundler_options.outfile = outfile;
                }
            }

            if (args.option("--root")) |root_dir| {
                if (root_dir.len > 0) {
                    ctx.bundler_options.root_dir = root_dir;
                }
            }

            if (args.option("--format")) |format_str| {
                const format = options.Format.fromString(format_str) orelse {
                    Output.errGeneric("Invalid format - must be esm, cjs, or iife", .{});
                    Global.crash();
                };

                switch (format) {
                    .internal_bake_dev => {
                        bun.Output.warn("--format={s} is for debugging only, and may experience breaking changes at any moment", .{format_str});
                        bun.Output.flush();
                    },
                    .cjs => {
                        if (ctx.args.target == null) {
                            ctx.args.target = .node;
                        }
                    },
                    else => {},
                }

                ctx.bundler_options.output_format = format;
                if (format != .cjs and ctx.bundler_options.bytecode) {
                    Output.errGeneric("format must be 'cjs' when bytecode is true. Eventually we'll add esm support as well.", .{});
                    Global.exit(1);
                }
            }

            if (args.flag("--splitting")) {
                ctx.bundler_options.code_splitting = true;
            }

            if (args.option("--entry-naming")) |entry_naming| {
                ctx.bundler_options.entry_naming = try strings.concat(allocator, &.{ "./", bun.strings.removeLeadingDotSlash(entry_naming) });
            }

            if (args.option("--chunk-naming")) |chunk_naming| {
                ctx.bundler_options.chunk_naming = try strings.concat(allocator, &.{ "./", bun.strings.removeLeadingDotSlash(chunk_naming) });
            }

            if (args.option("--asset-naming")) |asset_naming| {
                ctx.bundler_options.asset_naming = try strings.concat(allocator, &.{ "./", bun.strings.removeLeadingDotSlash(asset_naming) });
            }

            if (args.flag("--server-components")) {
                ctx.bundler_options.server_components = true;
                if (opts.target) |target| {
                    if (!bun.options.Target.from(target).isServerSide()) {
                        bun.Output.errGeneric("Cannot use client-side --target={s} with --server-components", .{@tagName(target)});
                        Global.crash();
                    } else {
                        opts.target = .bun;
                    }
                }
            }

            if (args.flag("--react-fast-refresh")) {
                ctx.bundler_options.react_fast_refresh = true;
            }

            if (args.option("--sourcemap")) |setting| {
                if (setting.len == 0) {
                    // In the future, Bun is going to make this default to .linked
                    opts.source_map = .linked;
                } else if (strings.eqlComptime(setting, "inline")) {
                    opts.source_map = .@"inline";
                } else if (strings.eqlComptime(setting, "none")) {
                    opts.source_map = .none;
                } else if (strings.eqlComptime(setting, "external")) {
                    opts.source_map = .external;
                } else if (strings.eqlComptime(setting, "linked")) {
                    opts.source_map = .linked;
                } else {
                    Output.prettyErrorln("<r><red>error<r>: Invalid sourcemap setting: \"{s}\"", .{setting});
                    Global.crash();
                }

                // when using --compile, only `external` works, as we do not
                // look at the source map comment. so after we validate the
                // user's choice was in the list, we secretly override it
                if (ctx.bundler_options.compile) {
                    opts.source_map = .external;
                }
            }
        }

        if (opts.entry_points.len == 0) {
            var entry_points = ctx.positionals;

            switch (comptime cmd) {
                .BuildCommand => {
                    if (entry_points.len > 0 and (strings.eqlComptime(
                        entry_points[0],
                        "build",
                    ) or strings.eqlComptime(entry_points[0], "bun"))) {
                        var out_entry = entry_points[1..];
                        for (entry_points, 0..) |entry, i| {
                            if (entry.len > 0) {
                                out_entry = out_entry[i..];
                                break;
                            }
                        }
                        entry_points = out_entry;
                    }
                },
                .RunCommand => {
                    if (entry_points.len > 0 and (strings.eqlComptime(
                        entry_points[0],
                        "run",
                    ) or strings.eqlComptime(
                        entry_points[0],
                        "r",
                    ))) {
                        entry_points = entry_points[1..];
                    }
                },
                else => {},
            }

            opts.entry_points = entry_points;
        }

        const jsx_factory = args.option("--jsx-factory");
        const jsx_fragment = args.option("--jsx-fragment");
        const jsx_import_source = args.option("--jsx-import-source");
        const jsx_runtime = args.option("--jsx-runtime");

        if (cmd == .AutoCommand or cmd == .RunCommand) {
            // "run.silent" in bunfig.toml
            if (args.flag("--silent")) {
                ctx.debug.silent = true;
            }

            if (args.option("--elide-lines")) |elide_lines| {
                if (elide_lines.len > 0) {
                    ctx.bundler_options.elide_lines = std.fmt.parseInt(usize, elide_lines, 10) catch {
                        Output.prettyErrorln("<r><red>error<r>: Invalid elide-lines: \"{s}\"", .{elide_lines});
                        Global.exit(1);
                    };
                }
            }

            if (opts.define) |define| {
                if (define.keys.len > 0)
                    bun.JSC.RuntimeTranspilerCache.is_disabled = true;
            }
        }

        if (cmd == .RunCommand or cmd == .AutoCommand or cmd == .BunxCommand) {
            // "run.bun" in bunfig.toml
            if (args.flag("--bun")) {
                ctx.debug.run_in_bun = true;
            }
        }

        opts.resolve = Api.ResolveMode.lazy;

        if (jsx_factory != null or
            jsx_fragment != null or
            jsx_import_source != null or
            jsx_runtime != null)
        {
            var default_factory = "".*;
            var default_fragment = "".*;
            var default_import_source = "".*;
            if (opts.jsx == null) {
                opts.jsx = Api.Jsx{
                    .factory = (jsx_factory orelse &default_factory),
                    .fragment = (jsx_fragment orelse &default_fragment),
                    .import_source = (jsx_import_source orelse &default_import_source),
                    .runtime = if (jsx_runtime) |runtime| try resolve_jsx_runtime(runtime) else Api.JsxRuntime.automatic,
                    .development = false,
                };
            } else {
                opts.jsx = Api.Jsx{
                    .factory = (jsx_factory orelse opts.jsx.?.factory),
                    .fragment = (jsx_fragment orelse opts.jsx.?.fragment),
                    .import_source = (jsx_import_source orelse opts.jsx.?.import_source),
                    .runtime = if (jsx_runtime) |runtime| try resolve_jsx_runtime(runtime) else opts.jsx.?.runtime,
                    .development = false,
                };
            }
        }

        if (cmd == .BuildCommand) {
            if (opts.entry_points.len == 0 and !ctx.bundler_options.bake) {
                Output.prettyln("<r><b>bun build <r><d>v" ++ Global.package_json_version_with_sha ++ "<r>", .{});
                Output.pretty("<r><red>error: Missing entrypoints. What would you like to bundle?<r>\n\n", .{});
                Output.flush();
                Output.pretty("Usage:\n  <d>$<r> <b><green>bun build<r> \\<entrypoint\\> [...\\<entrypoints\\>] <cyan>[...flags]<r>  \n", .{});
                Output.pretty("\nTo see full documentation:\n  <d>$<r> <b><green>bun build<r> --help\n", .{});
                Output.flush();
                Global.exit(1);
            }

            if (args.flag("--production")) {
                const any_html = for (opts.entry_points) |entry_point| {
                    if (strings.hasSuffixComptime(entry_point, ".html")) {
                        break true;
                    }
                } else false;
                if (any_html) {
                    ctx.bundler_options.css_chunking = true;
                }

                ctx.bundler_options.production = true;
            }
        }

        if (opts.log_level) |log_level| {
            logger.Log.default_log_level = switch (log_level) {
                .debug => logger.Log.Level.debug,
                .err => logger.Log.Level.err,
                .warn => logger.Log.Level.warn,
                else => logger.Log.Level.err,
            };
            ctx.log.level = logger.Log.default_log_level;
        }

        if (args.flag("--no-macros")) {
            ctx.debug.macros = .{ .disable = {} };
        }

        opts.output_dir = output_dir;
        if (output_file != null)
            ctx.debug.output_file = output_file.?;

        if (cmd == .RunCommand or cmd == .AutoCommand) {
            if (args.option("--shell")) |shell| {
                if (strings.eqlComptime(shell, "bun")) {
                    ctx.debug.use_system_shell = false;
                } else if (strings.eqlComptime(shell, "system")) {
                    ctx.debug.use_system_shell = true;
                } else {
                    Output.errGeneric("Expected --shell to be one of 'bun' or 'system'. Received: \"{s}\"", .{shell});
                    Global.exit(1);
                }
            }
        }

        if (Environment.show_crash_trace) {
            debug_flags.resolve_breakpoints = args.options("--breakpoint-resolve");
            debug_flags.print_breakpoints = args.options("--breakpoint-print");
        }

        return opts;
    }
};

const AutoCommand = struct {
    pub fn exec(allocator: std.mem.Allocator) !void {
        try HelpCommand.execWithReason(allocator, .invalid_command);
    }
};

pub const HelpCommand = struct {
    pub fn exec(allocator: std.mem.Allocator) !void {
        @branchHint(.cold);
        execWithReason(allocator, .explicit);
    }

    pub const Reason = enum {
        explicit,
        invalid_command,
    };

    // someone will get mad at me for this
    pub const packages_to_remove_filler = [_]string{
        "moment",
        "underscore",
        "jquery",
        "backbone",
        "redux",
        "browserify",
        "webpack",
        "left-pad",
        "is-array",
        "babel-core",
        "@parcel/core",
    };

    pub const packages_to_add_filler = [_]string{
        "elysia",
        "@shumai/shumai",
        "hono",
        "react",
        "lyra",
        "@remix-run/dev",
        "@evan/duckdb",
        "@zarfjs/zarf",
        "zod",
        "tailwindcss",
    };

    pub const packages_to_x_filler = [_]string{
        "bun-repl",
        "next",
        "vite",
        "prisma",
        "nuxi",
        "prettier",
        "eslint",
    };

    pub const packages_to_create_filler = [_]string{
        "next-app",
        "vite",
        "astro",
        "svelte",
        "elysia",
    };

    // the spacing between commands here is intentional
    pub const cli_helptext_fmt =
        \\<b>Usage:<r> <b>bun \<command\> <cyan>[...flags]<r> <b>[...args]<r>
        \\
        \\<b>Commands:<r>
        \\  <b><magenta>run<r>       <d>./my-script.ts<r>       Execute a file with Bun
        \\            <d>lint<r>                 Run a package.json script
        \\  <b><magenta>test<r>                           Run unit tests with Bun
        \\  <b><magenta>x<r>         <d>{s:<16}<r>     Execute a package binary (CLI), installing if needed <d>(bunx)<r>
        \\  <b><magenta>repl<r>                           Start a REPL session with Bun
        \\  <b><magenta>exec<r>                           Run a shell script directly with Bun
        \\
        \\  <b><blue>install<r>                        Install dependencies for a package.json <d>(bun i)<r>
        \\  <b><blue>add<r>       <d>{s:<16}<r>     Add a dependency to package.json <d>(bun a)<r>
        \\  <b><blue>remove<r>    <d>{s:<16}<r>     Remove a dependency from package.json <d>(bun rm)<r>
        \\  <b><blue>update<r>    <d>{s:<16}<r>     Update outdated dependencies
        \\  <b><blue>audit<r>                          Check installed packages for vulnerabilities
        \\  <b><blue>outdated<r>                       Display latest versions of outdated dependencies
        \\  <b><blue>link<r>      <d>[\<package\>]<r>          Register or link a local npm package
        \\  <b><blue>unlink<r>                         Unregister a local npm package
        \\  <b><blue>publish<r>                        Publish a package to the npm registry
        \\  <b><blue>patch <d>\<pkg\><r>                    Prepare a package for patching
        \\  <b><blue>pm <d>\<subcommand\><r>                Additional package management utilities
        \\
        \\  <b><yellow>build<r>     <d>./a.ts ./b.jsx<r>       Bundle TypeScript & JavaScript into a single file
        \\
        \\  <b><cyan>init<r>                           Start an empty Bun project from a built-in template
        \\  <b><cyan>create<r>    <d>{s:<16}<r>     Create a new project from a template <d>(bun c)<r>
        \\  <b><cyan>upgrade<r>                        Upgrade to latest version of Bun.
        \\  <d>\<command\><r> <b><cyan>--help<r>               Print help text for command.
        \\
    ;
    const cli_helptext_footer =
        \\
        \\Learn more about Bun:            <magenta>https://bun.sh/docs<r>
        \\Join our Discord community:      <blue>https://bun.sh/discord<r>
        \\
    ;

    pub fn printWithReason(comptime reason: Reason, show_all_flags: bool) void {
        var rand_state = std.Random.DefaultPrng.init(@as(u64, @intCast(@max(std.time.milliTimestamp(), 0))));
        const rand = rand_state.random();

        const package_x_i = rand.uintAtMost(usize, packages_to_x_filler.len - 1);
        const package_add_i = rand.uintAtMost(usize, packages_to_add_filler.len - 1);
        const package_remove_i = rand.uintAtMost(usize, packages_to_remove_filler.len - 1);
        const package_create_i = rand.uintAtMost(usize, packages_to_create_filler.len - 1);

        const args = .{
            packages_to_x_filler[package_x_i],
            packages_to_add_filler[package_add_i],
            packages_to_remove_filler[package_remove_i],
            packages_to_add_filler[(package_add_i + 1) % packages_to_add_filler.len],
            packages_to_create_filler[package_create_i],
        };

        switch (reason) {
            .explicit => {
                Output.pretty(
                    "<r><b><magenta>Bun<r> is a fast JavaScript runtime, package manager, bundler, and test runner. <d>(" ++
                        Global.package_json_version_with_revision ++
                        ")<r>\n\n" ++
                        cli_helptext_fmt,
                    args,
                );
                if (show_all_flags) {
                    Output.pretty("\n<b>Flags:<r>", .{});

                    const flags = Arguments.runtime_params_ ++ Arguments.auto_only_params ++ Arguments.base_params_;
                    clap.simpleHelpBunTopLevel(comptime &flags);
                    Output.pretty("\n\n(more flags in <b>bun install --help<r>, <b>bun test --help<r>, and <b>bun build --help<r>)\n", .{});
                }
                Output.pretty(cli_helptext_footer, .{});
            },
            .invalid_command => Output.prettyError(
                "<r><red>Uh-oh<r> not sure what to do with that command.\n\n" ++ cli_helptext_fmt,
                args,
            ),
        }

        Output.flush();
    }

    pub fn execWithReason(_: std.mem.Allocator, comptime reason: Reason) void {
        @branchHint(.cold);
        printWithReason(reason, false);

        if (reason == .invalid_command) {
            Global.exit(1);
        }
        Global.exit(0);
    }
};

pub const ReservedCommand = struct {
    pub fn exec(_: std.mem.Allocator) !void {
        @branchHint(.cold);
        const command_name = for (bun.argv[1..]) |arg| {
            if (arg.len > 1 and arg[0] == '-') continue;
            break arg;
        } else bun.argv[1];
        Output.prettyError(
            \\<r><red>Uh-oh<r>. <b><yellow>bun {s}<r> is a subcommand reserved for future use by Bun.
            \\
            \\If you were trying to run a package.json script called {s}, use <b><magenta>bun run {s}<r>.
            \\
        , .{ command_name, command_name, command_name });
        Output.flush();
        std.process.exit(1);
    }
};

const AddCompletions = @import("./cli/add_completions.zig");

/// This is set `true` during `Command.which()` if argv0 is "node", in which the CLI is going
/// to pretend to be node.js by always choosing RunCommand with a relative filepath.
///
/// Examples of how this differs from bun alone:
/// - `node build`               -> `bun run ./build`
/// - `node scripts/postinstall` -> `bun run ./scripts/postinstall`
pub var pretend_to_be_node = false;

/// This is set `true` during `Command.which()` if argv0 is "bunx"
pub var is_bunx_exe = false;

pub const Command = struct {
    pub fn get() Context {
        return global_cli_ctx;
    }

    pub const DebugOptions = struct {
        dump_environment_variables: bool = false,
        dump_limits: bool = false,
        fallback_only: bool = false,
        silent: bool = false,
        hot_reload: HotReload = HotReload.none,
        global_cache: options.GlobalCache = .auto,
        offline_mode_setting: ?Bunfig.OfflineMode = null,
        run_in_bun: bool = false,
        loaded_bunfig: bool = false,
        /// Disables using bun.shell.Interpreter for `bun run`, instead spawning cmd.exe
        use_system_shell: bool = !bun.Environment.isWindows,

        // technical debt
        macros: MacroOptions = MacroOptions.unspecified,
        editor: string = "",
        package_bundle_map: bun.StringArrayHashMapUnmanaged(options.BundlePackage) = bun.StringArrayHashMapUnmanaged(options.BundlePackage){},

        test_directory: []const u8 = "",
        output_file: []const u8 = "",
    };

    pub const MacroOptions = union(enum) { unspecified: void, disable: void, map: MacroMap };

    pub const HotReload = enum {
        none,
        hot,
        watch,
    };

    pub const TestOptions = struct {
        default_timeout_ms: u32 = 5 * std.time.ms_per_s,
        update_snapshots: bool = false,
        repeat_count: u32 = 0,
        run_todo: bool = false,
        only: bool = false,
        bail: u32 = 0,
        coverage: TestCommand.CodeCoverageOptions = .{},
        test_filter_regex: ?*RegularExpression = null,

        file_reporter: ?TestCommand.FileReporter = null,
        reporter_outfile: ?[]const u8 = null,
    };

    pub const Debugger = union(enum) {
        unspecified: void,
        enable: struct {
            path_or_port: []const u8 = "",
            wait_for_connection: bool = false,
            set_breakpoint_on_first_line: bool = false,
        },
    };

    pub const RuntimeOptions = struct {
        smol: bool = false,
        debugger: Debugger = .{ .unspecified = {} },
        if_present: bool = false,
        redis_preconnect: bool = false,
        eval: struct {
            script: []const u8 = "",
            eval_and_print: bool = false,
        } = .{},
        preconnect: []const []const u8 = &[_][]const u8{},
        dns_result_order: []const u8 = "verbatim",
        /// `--expose-gc` makes `globalThis.gc()` available. Added for Node
        /// compatibility.
        expose_gc: bool = false,
        preserve_symlinks_main: bool = false,
    };

    var global_cli_ctx: Context = undefined;
    var context_data: ContextData = undefined;

    pub const init = ContextData.create;

    pub const ContextData = struct {
        start_time: i128,
        args: Api.TransformOptions,
        log: *logger.Log,
        allocator: std.mem.Allocator,
        positionals: []const string = &.{},
        passthrough: []const string = &.{},
        install: ?*Api.BunInstall = null,

        debug: DebugOptions = .{},
        test_options: TestOptions = .{},
        bundler_options: BundlerOptions = .{},
        runtime_options: RuntimeOptions = .{},

        filters: []const []const u8 = &.{},

        preloads: []const string = &.{},
        has_loaded_global_config: bool = false,

        pub const BundlerOptions = struct {
            outdir: []const u8 = "",
            outfile: []const u8 = "",
            root_dir: []const u8 = "",
            public_path: []const u8 = "",
            entry_naming: []const u8 = "[dir]/[name].[ext]",
            chunk_naming: []const u8 = "./[name]-[hash].[ext]",
            asset_naming: []const u8 = "./[name]-[hash].[ext]",
            server_components: bool = false,
            react_fast_refresh: bool = false,
            code_splitting: bool = false,
            transform_only: bool = false,
            inline_entrypoint_import_meta_main: bool = false,
            minify_syntax: bool = false,
            minify_whitespace: bool = false,
            minify_identifiers: bool = false,
            ignore_dce_annotations: bool = false,
            emit_dce_annotations: bool = true,
            output_format: options.Format = .esm,
            bytecode: bool = false,
            banner: []const u8 = "",
            footer: []const u8 = "",
            css_chunking: bool = false,

            bake: bool = false,
            bake_debug_dump_server: bool = false,
            bake_debug_disable_minify: bool = false,

            production: bool = false,

            env_behavior: Api.DotEnvBehavior = .disable,
            env_prefix: []const u8 = "",
            elide_lines: ?usize = null,
            // Compile options
            compile: bool = false,
            compile_target: Cli.CompileTarget = .{},
            windows_hide_console: bool = false,
            windows_icon: ?[]const u8 = null,
        };

        pub fn create(allocator: std.mem.Allocator, log: *logger.Log, comptime command: Command.Tag) anyerror!Context {
            Cli.cmd = command;
            context_data = .{
                .args = std.mem.zeroes(Api.TransformOptions),
                .log = log,
                .start_time = start_time,
                .allocator = allocator,
            };
            global_cli_ctx = &context_data;

            if (comptime Command.Tag.uses_global_options.get(command)) {
                global_cli_ctx.args = try Arguments.parse(allocator, global_cli_ctx, command);
            }

            if (comptime Environment.isWindows) {
                if (global_cli_ctx.debug.hot_reload == .watch) {
                    if (!bun.windows.isWatcherChild()) {
                        // this is noreturn
                        bun.windows.becomeWatcherManager(allocator);
                    } else {
                        bun.auto_reload_on_crash = true;
                    }
                }
            }

            return global_cli_ctx;
        }
    };
    pub const Context = *ContextData;

    // std.process.args allocates!
    const ArgsIterator = struct {
        buf: [][:0]const u8,
        i: u32 = 0,

        pub fn next(this: *ArgsIterator) ?[]const u8 {
            if (this.buf.len <= this.i) {
                return null;
            }
            const i = this.i;
            this.i += 1;
            return this.buf[i];
        }

        pub fn skip(this: *ArgsIterator) bool {
            return this.next() != null;
        }
    };

    pub fn isBunX(argv0: []const u8) bool {
        if (Environment.isWindows) {
            return strings.endsWithComptime(argv0, "bunx.exe") or strings.endsWithComptime(argv0, "bunx");
        }
        return strings.endsWithComptime(argv0, "bunx");
    }

    pub fn isNode(argv0: []const u8) bool {
        if (Environment.isWindows) {
            return strings.endsWithComptime(argv0, "node.exe") or strings.endsWithComptime(argv0, "node");
        }
        return strings.endsWithComptime(argv0, "node");
    }

    pub fn which() Tag {
        var args_iter = ArgsIterator{ .buf = bun.argv };

        const argv0 = args_iter.next() orelse return .HelpCommand;

        if (isBunX(argv0)) {
            // if we are bunx, but NOT a symlink to bun. when we run `<self> install`, we dont
            // want to recursively run bunx. so this check lets us peek back into bun install.
            if (args_iter.next()) |next| {
                if (bun.strings.eqlComptime(next, "add") and bun.getRuntimeFeatureFlag(.BUN_INTERNAL_BUNX_INSTALL)) {
                    return .AddCommand;
                } else if (bun.strings.eqlComptime(next, "exec") and bun.getRuntimeFeatureFlag(.BUN_INTERNAL_BUNX_INSTALL)) {
                    return .ExecCommand;
                }
            }

            is_bunx_exe = true;
            return .BunxCommand;
        }

        if (isNode(argv0)) {
            @import("./deps/zig-clap/clap/streaming.zig").warn_on_unrecognized_flag = false;
            pretend_to_be_node = true;
            return .RunAsNodeCommand;
        }

        var next_arg = ((args_iter.next()) orelse return .AutoCommand);
        while (next_arg.len > 0 and next_arg[0] == '-' and !(next_arg.len > 1 and next_arg[1] == 'e')) {
            next_arg = ((args_iter.next()) orelse return .AutoCommand);
        }

        const first_arg_name = next_arg;
        const RootCommandMatcher = strings.ExactSizeMatcher(12);

        return switch (RootCommandMatcher.match(first_arg_name)) {
            RootCommandMatcher.case("init") => .InitCommand,
            RootCommandMatcher.case("build"), RootCommandMatcher.case("bun") => .BuildCommand,
            RootCommandMatcher.case("discord") => .DiscordCommand,
            RootCommandMatcher.case("upgrade") => .UpgradeCommand,
            RootCommandMatcher.case("completions") => .InstallCompletionsCommand,
            RootCommandMatcher.case("getcompletes") => .GetCompletionsCommand,
            RootCommandMatcher.case("link") => .LinkCommand,
            RootCommandMatcher.case("unlink") => .UnlinkCommand,
            RootCommandMatcher.case("x") => .BunxCommand,
            RootCommandMatcher.case("repl") => .ReplCommand,

            RootCommandMatcher.case("i"),
            RootCommandMatcher.case("install"),
            => brk: {
                for (args_iter.buf) |arg| {
                    if (arg.len > 0 and (strings.eqlComptime(arg, "-g") or strings.eqlComptime(arg, "--global"))) {
                        break :brk .AddCommand;
                    }
                }

                break :brk .InstallCommand;
            },
            RootCommandMatcher.case("c"), RootCommandMatcher.case("create") => .CreateCommand,

            RootCommandMatcher.case("test") => .TestCommand,

            RootCommandMatcher.case("pm") => .PackageManagerCommand,

            RootCommandMatcher.case("add"), RootCommandMatcher.case("a") => .AddCommand,

            RootCommandMatcher.case("update") => .UpdateCommand,
            RootCommandMatcher.case("patch") => .PatchCommand,
            RootCommandMatcher.case("patch-commit") => .PatchCommitCommand,

            RootCommandMatcher.case("r"),
            RootCommandMatcher.case("remove"),
            RootCommandMatcher.case("rm"),
            RootCommandMatcher.case("uninstall"),
            => .RemoveCommand,

            RootCommandMatcher.case("run") => .RunCommand,
            RootCommandMatcher.case("help") => .HelpCommand,

            RootCommandMatcher.case("exec") => .ExecCommand,

            RootCommandMatcher.case("outdated") => .OutdatedCommand,
            RootCommandMatcher.case("publish") => .PublishCommand,
            RootCommandMatcher.case("audit") => .AuditCommand,

            // These are reserved for future use by Bun, so that someone
            // doing `bun deploy` to run a script doesn't accidentally break
            // when we add our actual command
            RootCommandMatcher.case("deploy") => .ReservedCommand,
            RootCommandMatcher.case("cloud") => .ReservedCommand,
            RootCommandMatcher.case("info") => .ReservedCommand,
            RootCommandMatcher.case("config") => .ReservedCommand,
            RootCommandMatcher.case("use") => .ReservedCommand,
            RootCommandMatcher.case("auth") => .ReservedCommand,
            RootCommandMatcher.case("login") => .ReservedCommand,
            RootCommandMatcher.case("logout") => .ReservedCommand,
            RootCommandMatcher.case("whoami") => .ReservedCommand,
            RootCommandMatcher.case("prune") => .ReservedCommand,
            RootCommandMatcher.case("list") => .ReservedCommand,
            RootCommandMatcher.case("why") => .ReservedCommand,

            RootCommandMatcher.case("-e") => .AutoCommand,

            else => .AutoCommand,
        };
    }

    const default_completions_list = [_]string{
        "build",
        "install",
        "add",
        "run",
        "update",
        "link",
        "unlink",
        "remove",
        "create",
        "bun",
        "upgrade",
        "discord",
        "test",
        "pm",
        "x",
        "repl",
    };

    const reject_list = default_completions_list ++ [_]string{
        "build",
        "completions",
        "help",
    };

    pub fn start(allocator: std.mem.Allocator, log: *logger.Log) !void {
        if (comptime Environment.allow_assert) {
            if (bun.getenvZ("MI_VERBOSE") == null) {
                bun.Mimalloc.mi_option_set_enabled(.verbose, false);
            }
        }

        // bun build --compile entry point
        if (!bun.getRuntimeFeatureFlag(.BUN_BE_BUN)) {
            if (try bun.StandaloneModuleGraph.fromExecutable(bun.default_allocator)) |graph| {
                context_data = .{
                    .args = std.mem.zeroes(Api.TransformOptions),
                    .log = log,
                    .start_time = start_time,
                    .allocator = bun.default_allocator,
                };
                global_cli_ctx = &context_data;
                var ctx = global_cli_ctx;

                ctx.args.target = Api.Target.bun;
                if (bun.argv.len > 1) {
                    ctx.passthrough = bun.argv[1..];
                } else {
                    ctx.passthrough = &[_]string{};
                }

                try @import("./bun_js.zig").Run.bootStandalone(
                    ctx,
                    graph.entryPoint().name,
                    graph,
                );
                return;
            }
        }

        debug("argv: [{s}]", .{bun.fmt.fmtSlice(bun.argv, ", ")});

        const tag = which();

        switch (tag) {
            .DiscordCommand => return try DiscordCommand.exec(allocator),
            .HelpCommand => return try HelpCommand.exec(allocator),
            .ReservedCommand => return try ReservedCommand.exec(allocator),
            .InitCommand => return try InitCommand.exec(allocator, bun.argv[@min(2, bun.argv.len)..]),
            .BuildCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .BuildCommand) unreachable;
                const ctx = try Command.init(allocator, log, .BuildCommand);
                try BuildCommand.exec(ctx, null);
            },
            .InstallCompletionsCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .InstallCompletionsCommand) unreachable;
                try InstallCompletionsCommand.exec(allocator);
                return;
            },
            .InstallCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .InstallCommand) unreachable;
                const ctx = try Command.init(allocator, log, .InstallCommand);

                try InstallCommand.exec(ctx);
                return;
            },
            .AddCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .AddCommand) unreachable;
                const ctx = try Command.init(allocator, log, .AddCommand);

                try AddCommand.exec(ctx);
                return;
            },
            .UpdateCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .UpdateCommand) unreachable;
                const ctx = try Command.init(allocator, log, .UpdateCommand);

                try UpdateCommand.exec(ctx);
                return;
            },
            .PatchCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .PatchCommand) unreachable;
                const ctx = try Command.init(allocator, log, .PatchCommand);

                try PatchCommand.exec(ctx);
                return;
            },
            .PatchCommitCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .PatchCommitCommand) unreachable;
                const ctx = try Command.init(allocator, log, .PatchCommitCommand);

                try PatchCommitCommand.exec(ctx);
                return;
            },
            .OutdatedCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .OutdatedCommand) unreachable;
                const ctx = try Command.init(allocator, log, .OutdatedCommand);

                try OutdatedCommand.exec(ctx);
                return;
            },
            .PublishCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .PublishCommand) unreachable;
                const ctx = try Command.init(allocator, log, .PublishCommand);

                try PublishCommand.exec(ctx);
                return;
            },
            .AuditCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .AuditCommand) unreachable;
                const ctx = try Command.init(allocator, log, .AuditCommand);

                try AuditCommand.exec(ctx);
                unreachable;
            },
            .BunxCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .BunxCommand) unreachable;
                const ctx = try Command.init(allocator, log, .BunxCommand);

                try BunxCommand.exec(ctx, bun.argv[if (is_bunx_exe) 0 else 1..]);
                return;
            },
            .ReplCommand => {
                // TODO: Put this in native code.
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .BunxCommand) unreachable;
                var ctx = try Command.init(allocator, log, .BunxCommand);
                ctx.debug.run_in_bun = true; // force the same version of bun used. fixes bun-debug for example
                var args = bun.argv[0..];
                args[1] = "bun-repl";
                try BunxCommand.exec(ctx, args);
                return;
            },
            .RemoveCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .RemoveCommand) unreachable;
                const ctx = try Command.init(allocator, log, .RemoveCommand);

                try RemoveCommand.exec(ctx);
                return;
            },
            .LinkCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .LinkCommand) unreachable;
                const ctx = try Command.init(allocator, log, .LinkCommand);

                try LinkCommand.exec(ctx);
                return;
            },
            .UnlinkCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .UnlinkCommand) unreachable;
                const ctx = try Command.init(allocator, log, .UnlinkCommand);

                try UnlinkCommand.exec(ctx);
                return;
            },
            .PackageManagerCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .PackageManagerCommand) unreachable;
                const ctx = try Command.init(allocator, log, .PackageManagerCommand);

                // const maybe_subcommand, const maybe_arg = PackageManagerCommand.which(command_index);
                // if (maybe_subcommand) |subcommand| {
                //     return switch (subcommand) {
                //         inline else => |tag| try PackageManagerCommand.exec(ctx, tag),
                //     };
                // }

                // PackageManagerCommand.printHelp();

                // if (maybe_arg) |arg| {
                //     Output.errGeneric("\"{s}\" unknown command", .{arg});
                //     Global.crash();
                // }

                try PackageManagerCommand.exec(ctx);
                return;
            },
            .TestCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .TestCommand) unreachable;
                const ctx = try Command.init(allocator, log, .TestCommand);

                try TestCommand.exec(ctx);
                return;
            },
            .GetCompletionsCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .GetCompletionsCommand) unreachable;
                const ctx = try Command.init(allocator, log, .GetCompletionsCommand);
                var filter = ctx.positionals;

                for (filter, 0..) |item, i| {
                    if (strings.eqlComptime(item, "getcompletes")) {
                        if (i + 1 < filter.len) {
                            filter = filter[i + 1 ..];
                        } else {
                            filter = &[_]string{};
                        }

                        break;
                    }
                }
                var prefilled_completions: [AddCompletions.biggest_list]string = undefined;
                var completions = ShellCompletions{};

                if (filter.len == 0) {
                    completions = try RunCommand.completions(ctx, &default_completions_list, &reject_list, .all);
                } else if (strings.eqlComptime(filter[0], "s")) {
                    completions = try RunCommand.completions(ctx, null, &reject_list, .script);
                } else if (strings.eqlComptime(filter[0], "i")) {
                    completions = try RunCommand.completions(ctx, &default_completions_list, &reject_list, .script_exclude);
                } else if (strings.eqlComptime(filter[0], "b")) {
                    completions = try RunCommand.completions(ctx, null, &reject_list, .bin);
                } else if (strings.eqlComptime(filter[0], "r")) {
                    completions = try RunCommand.completions(ctx, null, &reject_list, .all);
                } else if (strings.eqlComptime(filter[0], "g")) {
                    completions = try RunCommand.completions(ctx, null, &reject_list, .all_plus_bun_js);
                } else if (strings.eqlComptime(filter[0], "j")) {
                    completions = try RunCommand.completions(ctx, null, &reject_list, .bun_js);
                } else if (strings.eqlComptime(filter[0], "z")) {
                    completions = try RunCommand.completions(ctx, null, &reject_list, .script_and_descriptions);
                } else if (strings.eqlComptime(filter[0], "a")) {
                    const FirstLetter = AddCompletions.FirstLetter;

                    outer: {
                        if (filter.len > 1 and filter[1].len > 0) {
                            const first_letter: FirstLetter = switch (filter[1][0]) {
                                'a' => FirstLetter.a,
                                'b' => FirstLetter.b,
                                'c' => FirstLetter.c,
                                'd' => FirstLetter.d,
                                'e' => FirstLetter.e,
                                'f' => FirstLetter.f,
                                'g' => FirstLetter.g,
                                'h' => FirstLetter.h,
                                'i' => FirstLetter.i,
                                'j' => FirstLetter.j,
                                'k' => FirstLetter.k,
                                'l' => FirstLetter.l,
                                'm' => FirstLetter.m,
                                'n' => FirstLetter.n,
                                'o' => FirstLetter.o,
                                'p' => FirstLetter.p,
                                'q' => FirstLetter.q,
                                'r' => FirstLetter.r,
                                's' => FirstLetter.s,
                                't' => FirstLetter.t,
                                'u' => FirstLetter.u,
                                'v' => FirstLetter.v,
                                'w' => FirstLetter.w,
                                'x' => FirstLetter.x,
                                'y' => FirstLetter.y,
                                'z' => FirstLetter.z,
                                else => break :outer,
                            };
                            AddCompletions.init(bun.default_allocator) catch bun.outOfMemory();
                            const results = AddCompletions.getPackages(first_letter);

                            var prefilled_i: usize = 0;
                            for (results) |cur| {
                                if (cur.len == 0 or !strings.hasPrefix(cur, filter[1])) continue;
                                prefilled_completions[prefilled_i] = cur;
                                prefilled_i += 1;
                                if (prefilled_i >= prefilled_completions.len) break;
                            }
                            completions.commands = prefilled_completions[0..prefilled_i];
                        }
                    }
                }
                completions.print();

                return;
            },
            .CreateCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .CreateCommand) unreachable;
                // These are templates from the legacy `bun create`
                // most of them aren't useful but these few are kinda nice.
                const HardcodedNonBunXList = bun.ComptimeStringMap(void, .{
                    .{"elysia"},
                    .{"elysia-buchta"},
                    .{"stric"},
                });

                // Create command wraps bunx
                const ctx = try Command.init(allocator, log, .CreateCommand);

                var args = try std.process.argsAlloc(allocator);

                if (args.len <= 2) {
                    Command.Tag.printHelp(.CreateCommand, false);
                    Global.exit(1);
                    return;
                }

                var template_name_start: usize = 0;
                var positionals: [2]string = .{ "", "" };
                var positional_i: usize = 0;

                var dash_dash_bun = false;
                var print_help = false;
                if (args.len > 2) {
                    const remainder = args[1..];
                    var remainder_i: usize = 0;
                    while (remainder_i < remainder.len and positional_i < positionals.len) : (remainder_i += 1) {
                        const slice = std.mem.trim(u8, bun.asByteSlice(remainder[remainder_i]), " \t\n");
                        if (slice.len > 0) {
                            if (!strings.hasPrefixComptime(slice, "--")) {
                                if (positional_i == 1) {
                                    template_name_start = remainder_i + 2;
                                }
                                positionals[positional_i] = slice;
                                positional_i += 1;
                            }
                            if (slice[0] == '-') {
                                if (strings.eqlComptime(slice, "--bun")) {
                                    dash_dash_bun = true;
                                } else if (strings.eqlComptime(slice, "--help") or strings.eqlComptime(slice, "-h")) {
                                    print_help = true;
                                }
                            }
                        }
                    }
                }

                if (print_help or
                    // "bun create --"
                    // "bun create -abc --"
                    positional_i == 0 or
                    positionals[1].len == 0)
                {
                    Command.Tag.printHelp(.CreateCommand, true);
                    Global.exit(0);
                    return;
                }

                const template_name = positionals[1];

                // if template_name is "react"
                // print message telling user to use "bun create vite" instead
                if (strings.eqlComptime(template_name, "react")) {
                    Output.prettyErrorln(
                        \\The "react" template has been deprecated.
                        \\It is recommended to use "react-app" or "vite" instead.
                        \\
                        \\To create a project using Create React App, run
                        \\
                        \\  <d>bun create react-app<r>
                        \\
                        \\To create a React project using Vite, run
                        \\
                        \\  <d>bun create vite<r>
                        \\
                        \\Then select "React" from the list of frameworks.
                        \\
                    , .{});
                    Global.exit(1);
                    return;
                }

                // if template_name is "next"
                // print message telling user to use "bun create next-app" instead
                if (strings.eqlComptime(template_name, "next")) {
                    Output.prettyErrorln(
                        \\<yellow>warn: No template <b>create-next<r> found.
                        \\To create a project with the official Next.js scaffolding tool, run
                        \\  <b>bun create next-app <cyan>[destination]<r>
                    , .{});
                    Global.exit(1);
                    return;
                }

                const create_command_info = try CreateCommand.extractInfo(ctx);
                const template = create_command_info.template;
                const example_tag = create_command_info.example_tag;

                const use_bunx = !HardcodedNonBunXList.has(template_name) and
                    (!strings.containsComptime(template_name, "/") or
                        strings.startsWithChar(template_name, '@')) and
                    example_tag != CreateCommandExample.Tag.local_folder;

                if (use_bunx) {
                    const bunx_args = try allocator.alloc([:0]const u8, 2 + args.len - template_name_start + @intFromBool(dash_dash_bun));
                    bunx_args[0] = "bunx";
                    if (dash_dash_bun) {
                        bunx_args[1] = "--bun";
                    }
                    bunx_args[1 + @as(usize, @intFromBool(dash_dash_bun))] = try BunxCommand.addCreatePrefix(allocator, template_name);
                    for (bunx_args[2 + @as(usize, @intFromBool(dash_dash_bun)) ..], args[template_name_start..]) |*dest, src| {
                        dest.* = src;
                    }

                    try BunxCommand.exec(ctx, bunx_args);
                    return;
                }

                try CreateCommand.exec(ctx, example_tag, template);
                return;
            },
            .RunCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .RunCommand) unreachable;
                const ctx = try Command.init(allocator, log, .RunCommand);
                ctx.args.target = .bun;

                if (ctx.filters.len > 0) {
                    FilterRun.runScriptsWithFilter(ctx) catch |err| {
                        Output.prettyErrorln("<r><red>error<r>: {s}", .{@errorName(err)});
                        Global.exit(1);
                    };
                }

                if (ctx.positionals.len > 0) {
                    if (try RunCommand.exec(ctx, .{ .bin_dirs_only = false, .log_errors = true, .allow_fast_run_for_extensions = false })) {
                        return;
                    }

                    Global.exit(1);
                }
            },
            .RunAsNodeCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .RunAsNodeCommand) unreachable;
                const ctx = try Command.init(allocator, log, .RunAsNodeCommand);
                bun.assert(pretend_to_be_node);
                try RunCommand.execAsIfNode(ctx);
            },
            .UpgradeCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .UpgradeCommand) unreachable;
                const ctx = try Command.init(allocator, log, .UpgradeCommand);
                try UpgradeCommand.exec(ctx);
                return;
            },
            .AutoCommand => {
                if (comptime bun.fast_debug_build_mode and bun.fast_debug_build_cmd != .AutoCommand) unreachable;

                const ctx = Command.init(allocator, log, .AutoCommand) catch |e| {
                    switch (e) {
                        error.MissingEntryPoint => {
                            HelpCommand.execWithReason(allocator, .explicit);
                            return;
                        },
                        else => {
                            return e;
                        },
                    }
                };
                ctx.args.target = .bun;

                if (ctx.filters.len > 0) {
                    FilterRun.runScriptsWithFilter(ctx) catch |err| {
                        Output.prettyErrorln("<r><red>error<r>: {s}", .{@errorName(err)});
                        Global.exit(1);
                    };
                }

                if (ctx.runtime_options.eval.script.len > 0) {
                    const trigger = bun.pathLiteral("/[eval]");
                    var entry_point_buf: [bun.MAX_PATH_BYTES + trigger.len]u8 = undefined;
                    const cwd = try std.posix.getcwd(&entry_point_buf);
                    @memcpy(entry_point_buf[cwd.len..][0..trigger.len], trigger);
                    ctx.passthrough = try std.mem.concat(ctx.allocator, []const u8, &.{ ctx.positionals, ctx.passthrough });
                    try BunJS.Run.boot(ctx, entry_point_buf[0 .. cwd.len + trigger.len], null);
                    return;
                }

                const extension: []const u8 = if (ctx.args.entry_points.len > 0)
                    std.fs.path.extension(ctx.args.entry_points[0])
                else
                    @as([]const u8, "");
                // KEYWORDS: open file argv argv0
                if (ctx.args.entry_points.len == 1) {
                    if (strings.eqlComptime(extension, ".lockb")) {
                        for (bun.argv) |arg| {
                            if (strings.eqlComptime(arg, "--hash")) {
                                var path_buf: bun.PathBuffer = undefined;
                                @memcpy(path_buf[0..ctx.args.entry_points[0].len], ctx.args.entry_points[0]);
                                path_buf[ctx.args.entry_points[0].len] = 0;
                                const lockfile_path = path_buf[0..ctx.args.entry_points[0].len :0];
                                const file = File.open(lockfile_path, bun.O.RDONLY, 0).unwrap() catch |err| {
                                    Output.err(err, "failed to open lockfile", .{});
                                    Global.crash();
                                };
                                try PackageManagerCommand.printHash(ctx, file);
                                return;
                            }
                        }

                        try Install.Lockfile.Printer.print(
                            ctx.allocator,
                            ctx.log,
                            ctx.args.entry_points[0],
                            .yarn,
                        );

                        return;
                    }
                }

                if (ctx.positionals.len > 0) {
                    if (ctx.filters.len > 0) {
                        Output.prettyln("<r><yellow>warn<r>: Filters are ignored for auto command", .{});
                    }
                    if (try RunCommand.exec(ctx, .{ .bin_dirs_only = true, .log_errors = !ctx.runtime_options.if_present, .allow_fast_run_for_extensions = true })) {
                        return;
                    }
                    return;
                }

                Output.flush();
                try HelpCommand.exec(allocator);
            },
            .ExecCommand => {
                const ctx = try Command.init(allocator, log, .ExecCommand);

                if (ctx.positionals.len > 1) {
                    try ExecCommand.exec(ctx);
                } else Tag.printHelp(.ExecCommand, true);
            },
        }
    }

    pub const Tag = enum {
        AddCommand,
        AutoCommand,
        BuildCommand,
        BunxCommand,
        CreateCommand,
        DiscordCommand,
        GetCompletionsCommand,
        HelpCommand,
        InitCommand,
        InstallCommand,
        InstallCompletionsCommand,
        LinkCommand,
        PackageManagerCommand,
        RemoveCommand,
        RunCommand,
        RunAsNodeCommand, // arg0 == 'node'
        TestCommand,
        UnlinkCommand,
        UpdateCommand,
        UpgradeCommand,
        ReplCommand,
        ReservedCommand,
        ExecCommand,
        PatchCommand,
        PatchCommitCommand,
        OutdatedCommand,
        PublishCommand,
        AuditCommand,

        /// Used by crash reports.
        ///
        /// This must be kept in sync with https://github.com/oven-sh/bun.report/blob/62601d8aafb9c0d29554dfc3f8854044ec04d367/backend/remap.ts#L10
        pub fn char(this: Tag) u8 {
            return switch (this) {
                .AddCommand => 'I',
                .AutoCommand => 'a',
                .BuildCommand => 'b',
                .BunxCommand => 'B',
                .CreateCommand => 'c',
                .DiscordCommand => 'D',
                .GetCompletionsCommand => 'g',
                .HelpCommand => 'h',
                .InitCommand => 'j',
                .InstallCommand => 'i',
                .InstallCompletionsCommand => 'C',
                .LinkCommand => 'l',
                .PackageManagerCommand => 'P',
                .RemoveCommand => 'R',
                .RunCommand => 'r',
                .RunAsNodeCommand => 'n',
                .TestCommand => 't',
                .UnlinkCommand => 'U',
                .UpdateCommand => 'u',
                .UpgradeCommand => 'p',
                .ReplCommand => 'G',
                .ReservedCommand => 'w',
                .ExecCommand => 'e',
                .PatchCommand => 'x',
                .PatchCommitCommand => 'z',
                .OutdatedCommand => 'o',
                .PublishCommand => 'k',
                .AuditCommand => 'A',
            };
        }

        pub fn params(comptime cmd: Tag) []const Arguments.ParamType {
            return comptime &switch (cmd) {
                .AutoCommand => Arguments.auto_params,
                .RunCommand, .RunAsNodeCommand => Arguments.run_params,
                .BuildCommand => Arguments.build_params,
                .TestCommand => Arguments.test_params,
                .BunxCommand => Arguments.run_params,
                else => Arguments.base_params_ ++ Arguments.runtime_params_ ++ Arguments.transpiler_params_,
            };
        }

        pub fn printHelp(comptime cmd: Tag, show_all_flags: bool) void {
            switch (cmd) {

                // the output of --help uses the following syntax highlighting
                // template: <b>Usage<r>: <b><green>bun <command><r> <cyan>[flags]<r> <blue>[arguments]<r>
                // use [foo] for multiple arguments or flags for foo.
                // use <bar> to emphasize 'bar'

                // these commands do not use Context
                // .DiscordCommand => return try DiscordCommand.exec(allocator),
                // .HelpCommand => return try HelpCommand.exec(allocator),
                // .ReservedCommand => return try ReservedCommand.exec(allocator),

                // these commands are implemented in install.zig
                // Command.Tag.InstallCommand => {},
                // Command.Tag.AddCommand => {},
                // Command.Tag.RemoveCommand => {},
                // Command.Tag.UpdateCommand => {},
                // Command.Tag.PackageManagerCommand => {},
                // Command.Tag.LinkCommand => {},
                // Command.Tag.UnlinkCommand => {},

                // fall back to HelpCommand.printWithReason
                Command.Tag.AutoCommand => {
                    HelpCommand.printWithReason(.explicit, show_all_flags);
                },
                .RunCommand, .RunAsNodeCommand => {
                    RunCommand_.printHelp(null);
                },

                .InitCommand => {
                    const intro_text =
                        \\<b>Usage<r>: <b><green>bun init<r> <cyan>[flags]<r> <blue>[\<folder\>]<r>
                        \\  Initialize a Bun project in the current directory.
                        \\  Creates a package.json, tsconfig.json, and bunfig.toml if they don't exist.
                        \\
                        \\<b>Flags<r>:
                        \\      <cyan>--help<r>             Print this menu
                        \\  <cyan>-y, --yes<r>              Accept all default options
                        \\  <cyan>-m, --minimal<r>          Only initialize type definitions
                        \\  <cyan>-r, --react<r>            Initialize a React project
                        \\      <cyan>--react=tailwind<r>   Initialize a React project with TailwindCSS
                        \\      <cyan>--react=shadcn<r>     Initialize a React project with @shadcn/ui and TailwindCSS
                        \\
                        \\<b>Examples:<r>
                        \\  <b><green>bun init<r>
                        \\  <b><green>bun init<r> <cyan>--yes<r>
                        \\  <b><green>bun init<r> <cyan>--react<r>
                        \\  <b><green>bun init<r> <cyan>--react=tailwind<r> <blue>my-app<r>
                    ;

                    Output.pretty(intro_text ++ "\n", .{});
                    Output.flush();
                },

                Command.Tag.BunxCommand => {
                    Output.prettyErrorln(
                        \\<b>Usage<r>: <b><green>bunx<r> <cyan>[flags]<r> <blue>\<package\><r><d>\<@version\><r> [flags and arguments for the package]<r>
                        \\Execute an npm package executable (CLI), automatically installing into a global shared cache if not installed in node_modules.
                        \\
                        \\Flags:
                        \\  <cyan>--bun<r>      Force the command to run with Bun instead of Node.js
                        \\
                        \\Examples<d>:<r>
                        \\  <b><green>bunx<r> <blue>prisma<r> migrate<r>
                        \\  <b><green>bunx<r> <blue>prettier<r> foo.js<r>
                        \\  <b><green>bunx<r> <cyan>--bun<r> <blue>vite<r> dev foo.js<r>
                        \\
                    , .{});
                },
                Command.Tag.BuildCommand => {
                    const intro_text =
                        \\<b>Usage<r>:
                        \\  Transpile and bundle one or more files.
                        \\  <b><green>bun build<r> <cyan>[flags]<r> <blue>\<entrypoint\><r>
                    ;

                    const outro_text =
                        \\<b>Examples:<r>
                        \\  <d>Frontend web apps:<r>
                        \\  <b><green>bun build<r> <cyan>--outfile=bundle.js<r> <blue>./src/index.ts<r>
                        \\  <b><green>bun build<r> <cyan>--minify --splitting --outdir=out<r> <blue>./index.jsx ./lib/worker.ts<r>
                        \\
                        \\  <d>Bundle code to be run in Bun (reduces server startup time)<r>
                        \\  <b><green>bun build<r> <cyan>--target=bun --outfile=server.js<r> <blue>./server.ts<r>
                        \\
                        \\  <d>Creating a standalone executable (see https://bun.sh/docs/bundler/executables)<r>
                        \\  <b><green>bun build<r> <cyan>--compile --outfile=my-app<r> <blue>./cli.ts<r>
                        \\
                        \\A full list of flags is available at <magenta>https://bun.sh/docs/bundler<r>
                        \\
                    ;

                    Output.pretty(intro_text ++ "\n\n", .{});
                    Output.flush();
                    Output.pretty("<b>Flags:<r>", .{});
                    Output.flush();
                    clap.simpleHelp(&Arguments.build_only_params);
                    Output.pretty("\n\n" ++ outro_text, .{});
                    Output.flush();
                },
                Command.Tag.TestCommand => {
                    const intro_text =
                        \\<b>Usage<r>: <b><green>bun test<r> <cyan>[flags]<r> <blue>[\<patterns\>]<r>
                        \\  Run all matching test files and print the results to stdout
                    ;
                    const outro_text =
                        \\<b>Examples:<r>
                        \\  <d>Run all test files<r>
                        \\  <b><green>bun test<r>
                        \\
                        \\  <d>Run all test files with "foo" or "bar" in the file name<r>
                        \\  <b><green>bun test<r> <blue>foo bar<r>
                        \\
                        \\  <d>Run all test files, only including tests whose names includes "baz"<r>
                        \\  <b><green>bun test<r> <cyan>--test-name-pattern<r> <blue>baz<r>
                        \\
                        \\Full documentation is available at <magenta>https://bun.sh/docs/cli/test<r>
                        \\
                    ;

                    Output.pretty(intro_text, .{});
                    Output.flush();
                    Output.pretty("\n\n<b>Flags:<r>", .{});
                    Output.flush();
                    clap.simpleHelp(&Arguments.test_only_params);
                    Output.pretty("\n\n", .{});
                    Output.pretty(outro_text, .{});
                    Output.flush();
                },
                Command.Tag.CreateCommand => {
                    const intro_text =
                        \\<b>Usage<r><d>:<r>
                        \\  <b><green>bun create<r> <magenta>\<MyReactComponent.(jsx|tsx)\><r> 
                        \\  <b><green>bun create<r> <magenta>\<template\><r> <cyan>[...flags]<r> <blue>dest<r> 
                        \\  <b><green>bun create<r> <magenta>\<github-org/repo\><r> <cyan>[...flags]<r> <blue>dest<r>
                        \\
                        \\<b>Environment variables<r><d>:<r>
                        \\  <cyan>GITHUB_TOKEN<r>         <d>Supply a token to download code from GitHub with a higher rate limit<r>
                        \\  <cyan>GITHUB_API_DOMAIN<r>    <d>Configure custom/enterprise GitHub domain. Default "api.github.com"<r>
                        \\  <cyan>NPM_CLIENT<r>           <d>Absolute path to the npm client executable<r>
                        \\  <cyan>BUN_CREATE_DIR<r>       <d>Custom path for global templates (default: $HOME/.bun-create)<r>
                    ;

                    const outro_text =
                        \\<b>React Component Projects<r><d>:<r>
                        \\  • Turn an existing React component into a complete frontend dev environment
                        \\  • Automatically starts a hot-reloading dev server
                        \\  • Auto-detects & configures TailwindCSS and shadcn/ui
                        \\
                        \\  <b><magenta>bun create \<MyReactComponent.(jsx|tsx)\><r>
                        \\
                        \\<b>Templates<r><d>:<r>
                        \\  • NPM: Runs <b><magenta>bunx create-\<template\><r> with given arguments
                        \\  • GitHub: Downloads repository contents as template
                        \\  • Local: Uses templates from $HOME/.bun-create/\<name\> or ./.bun-create/\<name\>
                        \\
                        \\Learn more: <magenta>https://bun.sh/docs/cli/bun-create<r>
                        \\
                    ;

                    Output.pretty(intro_text, .{});
                    Output.pretty("\n\n", .{});
                    Output.pretty(outro_text, .{});
                    Output.flush();
                },
                Command.Tag.HelpCommand => {
                    HelpCommand.printWithReason(.explicit);
                },
                Command.Tag.UpgradeCommand => {
                    const intro_text =
                        \\<b>Usage<r>: <b><green>bun upgrade<r> <cyan>[flags]<r>
                        \\  Upgrade Bun
                    ;
                    const outro_text =
                        \\<b>Examples:<r>
                        \\  <d>Install the latest {s} version<r>
                        \\  <b><green>bun upgrade<r>
                        \\
                        \\  <d>{s}<r>
                        \\  <b><green>bun upgrade<r> <cyan>--{s}<r>
                        \\
                        \\Full documentation is available at <magenta>https://bun.sh/docs/installation#upgrading<r>
                        \\
                    ;

                    const args = comptime switch (Environment.is_canary) {
                        true => .{ "canary", "Switch from the canary version back to the latest stable release", "stable" },
                        false => .{ "stable", "Install the most recent canary version of Bun", "canary" },
                    };

                    Output.pretty(intro_text, .{});
                    Output.pretty("\n\n", .{});
                    Output.flush();
                    Output.pretty(outro_text, args);
                    Output.flush();
                },
                Command.Tag.ReplCommand => {
                    const intro_text =
                        \\<b>Usage<r>: <b><green>bun repl<r> <cyan>[flags]<r>
                        \\  Open a Bun REPL
                        \\
                    ;

                    Output.pretty(intro_text, .{});
                    Output.flush();
                },

                Command.Tag.GetCompletionsCommand => {
                    Output.pretty("<b>Usage<r>: <b><green>bun getcompletes<r>", .{});
                    Output.flush();
                },
                Command.Tag.InstallCompletionsCommand => {
                    Output.pretty("<b>Usage<r>: <b><green>bun completions<r>", .{});
                    Output.flush();
                },
                Command.Tag.PatchCommand => {
                    Install.PackageManager.CommandLineArguments.printHelp(.patch);
                },
                Command.Tag.PatchCommitCommand => {
                    Install.PackageManager.CommandLineArguments.printHelp(.@"patch-commit");
                },
                Command.Tag.ExecCommand => {
                    Output.pretty(
                        \\<b>Usage: bun exec <r><cyan>\<script\><r>
                        \\
                        \\Execute a shell script directly from Bun.
                        \\
                        \\<b><red>Note<r>: If executing this from a shell, make sure to escape the string!
                        \\
                        \\<b>Examples<d>:<r>
                        \\  <b>bun exec "echo hi"<r>
                        \\  <b>bun exec "echo \"hey friends\"!"<r>
                        \\
                    , .{});
                    Output.flush();
                },
                .OutdatedCommand, .PublishCommand, .AuditCommand => {
                    Install.PackageManager.CommandLineArguments.printHelp(switch (cmd) {
                        .OutdatedCommand => .outdated,
                        .PublishCommand => .publish,
                        .AuditCommand => .audit,
                    });
                },
                else => {
                    HelpCommand.printWithReason(.explicit);
                },
            }
        }

        pub fn readGlobalConfig(this: Tag) bool {
            return switch (this) {
                .BunxCommand,
                .PackageManagerCommand,
                .InstallCommand,
                .AddCommand,
                .RemoveCommand,
                .UpdateCommand,
                .PatchCommand,
                .PatchCommitCommand,
                .OutdatedCommand,
                .PublishCommand,
                .AuditCommand,
                => true,
                else => false,
            };
        }

        pub fn isNPMRelated(this: Tag) bool {
            return switch (this) {
                .BunxCommand,
                .LinkCommand,
                .UnlinkCommand,
                .PackageManagerCommand,
                .InstallCommand,
                .AddCommand,
                .RemoveCommand,
                .UpdateCommand,
                .PatchCommand,
                .PatchCommitCommand,
                .OutdatedCommand,
                .PublishCommand,
                .AuditCommand,
                => true,
                else => false,
            };
        }

        pub const loads_config: std.EnumArray(Tag, bool) = std.EnumArray(Tag, bool).initDefault(false, .{
            .BuildCommand = true,
            .TestCommand = true,
            .InstallCommand = true,
            .AddCommand = true,
            .RemoveCommand = true,
            .UpdateCommand = true,
            .PatchCommand = true,
            .PatchCommitCommand = true,
            .PackageManagerCommand = true,
            .BunxCommand = true,
            .AutoCommand = true,
            .RunCommand = true,
            .RunAsNodeCommand = true,
            .OutdatedCommand = true,
            .PublishCommand = true,
            .AuditCommand = true,
        });

        pub const always_loads_config: std.EnumArray(Tag, bool) = std.EnumArray(Tag, bool).initDefault(false, .{
            .BuildCommand = true,
            .TestCommand = true,
            .InstallCommand = true,
            .AddCommand = true,
            .RemoveCommand = true,
            .UpdateCommand = true,
            .PatchCommand = true,
            .PatchCommitCommand = true,
            .PackageManagerCommand = true,
            .BunxCommand = true,
            .OutdatedCommand = true,
            .PublishCommand = true,
            .AuditCommand = true,
        });

        pub const uses_global_options: std.EnumArray(Tag, bool) = std.EnumArray(Tag, bool).initDefault(true, .{
            .CreateCommand = false,
            .InstallCommand = false,
            .AddCommand = false,
            .RemoveCommand = false,
            .UpdateCommand = false,
            .PatchCommand = false,
            .PatchCommitCommand = false,
            .PackageManagerCommand = false,
            .LinkCommand = false,
            .UnlinkCommand = false,
            .BunxCommand = false,
            .OutdatedCommand = false,
            .PublishCommand = false,
            .AuditCommand = false,
        });
    };
};

pub fn printVersionAndExit() noreturn {
    @branchHint(.cold);
    Output.writer().writeAll(Global.package_json_version ++ "\n") catch {};
    Global.exit(0);
}

pub fn printRevisionAndExit() noreturn {
    @branchHint(.cold);
    Output.writer().writeAll(Global.package_json_version_with_revision ++ "\n") catch {};
    Global.exit(0);
}
