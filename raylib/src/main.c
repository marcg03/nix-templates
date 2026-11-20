#include <math.h>
#include "raylib.h"
#if defined(PLATFORM_WEB)
#include <emscripten/emscripten.h>
#endif

#define W 1280
#define H 720

#ifndef ASSETS_DIR
#define ASSETS_DIR "assets"
#endif
const char *AssetPath(const char *file) { return TextFormat("%s/%s", ASSETS_DIR, file); }

static float scale;
static Vector2 offset;

static Vector2 GameMouse(void) {
    Vector2 m = GetMousePosition();
    return (Vector2){ (m.x - offset.x) / scale, (m.y - offset.y) / scale };
}

static void Frame(void) {
    int sw = GetScreenWidth(), sh = GetScreenHeight();
    scale = fminf((float)sw / W, (float)sh / H);
    offset = (Vector2){ (sw - W * scale) / 2, (sh - H * scale) / 2 };
    Vector2 mouse = GameMouse();

    BeginDrawing();
    ClearBackground(BLACK);
    BeginMode2D((Camera2D){ .offset = offset, .zoom = scale });

    DrawRectangle(0, 0, W, H, RAYWHITE);
    const char *msg = "Hello, raylib!";
    int size = 60;
    DrawText(msg, (W - MeasureText(msg, size)) / 2, (H - size) / 2, size, DARKGRAY);
    if (mouse.x >= 0 && mouse.x <= W && mouse.y >= 0 && mouse.y <= H) DrawCircleV(mouse, 12, RED);

    EndMode2D();
    EndDrawing();
}

int main(void) {
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_VSYNC_HINT | FLAG_MSAA_4X_HINT);
    InitWindow(W, H, "raylib game");
    SetWindowMinSize(320, 180);

#if defined(PLATFORM_WEB)
    emscripten_set_main_loop(Frame, 0, 1);
#else
    SetTargetFPS(60);
    while (!WindowShouldClose()) Frame();
#endif
    CloseWindow();
    return 0;
}
