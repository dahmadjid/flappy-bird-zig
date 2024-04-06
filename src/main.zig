const std = @import("std");
const log = std.log;
const rl = @import("raylib");

const width = 1024;
const height = 1024;

const Point = struct {
    x: i32,
    y: i32,
};

const Wall = struct {
    pos: i32 = 0,
    pointing_up: bool = false,
};

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

const GameState = struct {
    player_pos: Point = .{ .x = 160, .y = 320 },
    player_speed: rl.Vector2 = .{ .x = 0, .y = 0 },
    walls: std.ArrayList(Wall) = std.ArrayList(Wall).init(allocator),

    pub fn update(self: *GameState) void {
        self.update_player_pos(rl.isKeyPressed(rl.KeyboardKey.key_space));
        self.update_walls();
    }

    pub fn update_player_pos(self: *GameState, space_pressed: bool) void {
        self.player_pos.y += @intFromFloat(self.player_speed.y);
        if (space_pressed) {
            self.player_speed.y = -10;
        } else {
            self.player_speed.y += 0.5;
        }
    }

    pub fn update_walls(self: *GameState) void {
        var start_index: usize = 0;

        for (0..self.walls.items.len) |i| {
            var r = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));

            self.walls.items[i].pos -= 5;
            if (self.walls.items[i].pos < 0) {
                const rand: i32 = @intCast(@rem(r.next(), 30));
                const rand_pointing: bool = @rem(r.next(), 3) != 0;
                self.walls.append(Wall{ .pos = width + rand, .pointing_up = rand_pointing }) catch unreachable;
                start_index += 1;
            }
        }
        var new_walls = std.ArrayList(Wall).init(allocator);
        new_walls.resize(self.walls.items.len - start_index) catch unreachable;
        for (start_index..self.walls.items.len, 0..new_walls.items.len) |i, j| {
            new_walls.items[j] = self.walls.items[i];
        }

        self.walls.clearAndFree();
        self.walls = new_walls;
    }
};

var state: GameState = .{};

pub fn main() !void {
    defer arena.deinit();
    log.info("\n", .{});
    log.info("{} {}", state.player_pos);

    rl.initWindow(width, height, "glfw");
    rl.setWindowPosition(3200, 700);
    rl.setTargetFPS(60);
    try state.walls.append(Wall{ .pos = 500, .pointing_up = true });
    try state.walls.append(Wall{ .pos = 800, .pointing_up = false });
    try state.walls.append(Wall{ .pos = 1200, .pointing_up = false });
    var game_started = false;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.drawCircleLines(state.player_pos.x, state.player_pos.y, 20, rl.Color.white);

        for (state.walls.items) |wall| {
            rl.drawLine(wall.pos, if (wall.pointing_up) height else 0, wall.pos, if (wall.pointing_up) height - 600 else 600, rl.Color.white);
        }

        rl.clearBackground(rl.Color.black);
        rl.endDrawing();
        if (game_started) {
            state.update();
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            game_started = true;
        }
    }
}
