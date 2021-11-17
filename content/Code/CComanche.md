---
title: "CComanche (C, SDL2)"
date: 2020-03-11T23:00:35+02:00
draft: true
comments: false
images:
---

## Lien 
[Github](https://github.com/rachartier/CComanche)

Petit projet qui permet de "voler" dans un vaisseau en s'inspirant du moteur du jeu "Comanche".

Le terrain est un terrain infini, avec plusieurs niveaux disponibles.
Le moteur de jeu est très simple. 2 images permettent de répresenter le niveau:
	- Une image de couleurs 
	- Une image en noir et blanc représentant la hauteur du terrain
	
Ces deux images alors combinées permettent la création d'un niveau. L'algorithme utilisé va alors scanner les différents pixels en partant de la fin, puis se rapprocher avec un certain delta à chaque itération du joueur. Les lignes sont alors tracées verticalements, et cela va donner une impression de profondeur. Tout cela répété 60 fois par seconde et on obtient un jeu fluide où l'on peut se déplacer librement dans un monde infini.

Le projet doit être compilé avec la SDL2.

## Code

```c
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL2_framerate.h>
#include <math.h>

#define SCREEN_HEIGHT 480
#define SCREEN_WIDTH 640
#define FPS 60

#define PRECISION 0.01
#define DEADZONE 10

#define TURNING_SPEED 0.9
#define CAMERA_SPEED 150.0

struct point_t {
    float x;
    float y;
};

struct camera_t {
    struct point_t position;

    float height;
    float angle;
    float distance;
    
    float horizon;
};

struct ship_t {
    float x_speed;
    float y_speed;
};

struct map_t {
    SDL_Surface *img_heightmap;
    SDL_Surface *img_colormap;

    uint8_t *heightmap;
    uint8_t *colormap;

    unsigned width;
    unsigned height;
    unsigned shift;
};

struct screen_t {
    SDL_Renderer *renderer;
    unsigned     ybuffer[SCREEN_WIDTH];
    uint8_t      buffer[SCREEN_WIDTH * SCREEN_HEIGHT * 3];
    uint8_t      blank[SCREEN_WIDTH * SCREEN_HEIGHT * 3];

    int height;
    int width;
};

uint32_t getpixel(SDL_Surface *surface, int x, int y)
{
    return *((Uint8 *)surface->pixels + y * surface->pitch + x);
}

uint8_t *load_img_into_map(SDL_Surface *img, struct map_t *map) {
    int w = map->width;
    int h = map->height;

    uint8_t *arr = malloc(w * h * sizeof(*arr));

    SDL_LockSurface(img);
    for(int x = 0; x < w; ++x) {
        for(int y = 0; y < h; ++y) {
            arr[y * h + x] = getpixel(img, x, y);  
        }
    } 
    SDL_UnlockSurface(img);

    return arr;
}

void load_map(struct map_t *map, int level_number) {
    static const uint8_t level[][2] = {
       {1,1},
       {2,2},
       {3,3},
       {4,4},
       {5,5},
       {6,6},
       {7,7},
       {8,6},
       {9,9},
       {10,10},
       {11,11},
       {12,11},
       {13,13},
       {14,14},
       {15,15},
       {16,16},
       {17,17},
       {18,18},
       {19,19},
       {20,20},
       {21,21},
       {22,22},
       {23,21},
       {24,24},
       {25,25},
    };

    if(map->img_heightmap)
        SDL_FreeSurface(map->img_heightmap);

    if(map->img_colormap)
        SDL_FreeSurface(map->img_colormap);

    char buf_color[64];
    char buf_height[64];

    sprintf(buf_color, "./color_map/C%dW.png", level[level_number][0]);
    sprintf(buf_height, "./height_map/D%d.png", level[level_number][1]);
    
    map->img_heightmap = IMG_Load(buf_height);
    map->img_colormap = IMG_Load(buf_color);

    if(!map->img_colormap) {
        sprintf(buf_color, "./color_map/C%d.png", level[level_number][0]);
        map->img_colormap = IMG_Load(buf_color);
    }

    if(map->colormap)
        free(map->colormap);
    if(map->heightmap)
        free(map->heightmap);

    map->colormap = load_img_into_map(map->img_colormap, map);
    map->heightmap = load_img_into_map(map->img_heightmap, map);
}

uint8_t get_value_map(struct map_t *map, uint8_t *arr, int x, int y) {
    return arr[y * map->height + x];  
}

void draw_vline(struct screen_t *screen, int x, int y, int length, int r, int g, int b) {
    if(y < 0)
        y = 0;

    for(; y < length && y < screen->height; ++y) {
        unsigned offset = (screen->width * 3 * y) + x * 3;

        screen->buffer[offset + 0] = r;
        screen->buffer[offset + 1] = g;
        screen->buffer[offset + 2] = b;
    } 
} 

void render(struct screen_t *screen,
            struct camera_t *camera, 
            struct map_t *map, float scale_height) {

    float sinphi = sin(camera->angle);
    float cosphi = cos(camera->angle);
    
    for(int i = 0; i < screen->width; ++i) {
        screen->ybuffer[i] = screen->height; 

        for(int j = 0; j < screen->height; ++j) {
            unsigned offset = (screen->width * 3 * j) + i * 3;
            screen->buffer[offset] = 0x99;
            screen->buffer[offset + 1] = 0xcc;
            screen->buffer[offset + 2] = 0xff;
        }
    }

    float dz = 1.0f;
    float z  = 1.0f;

    while(z < camera->distance) {
        struct point_t point_left = {
            .x = (-cosphi * z - sinphi * z),
            .y = ( sinphi * z - cosphi * z)
        };

        struct point_t point_right = {
            .x = ( cosphi * z - sinphi * z),
            .y = (-sinphi * z - cosphi * z)
        };
        
        float dx = (point_right.x - point_left.x) / screen->width;
        float dy = (point_right.y - point_left.y) / screen->width;
        
        point_left.x += camera->position.x;
        point_left.y += camera->position.y;

        float invz = 1.0f / z * scale_height;

        for(int x = 0; x < screen->width; ++x) {
            uint16_t px = ((uint16_t)point_left.x & map->shift);
            uint16_t py = ((uint16_t)point_left.y & map->shift);

            uint8_t pos_height = get_value_map(map, map->heightmap, px, py);
            uint8_t pos_color  = get_value_map(map, map->colormap, px, py);
                
            float height_screen = (camera->height - pos_height) * invz + camera->horizon;
            uint8_t r,g,b;

            SDL_GetRGB(pos_color, map->img_colormap->format, &r, &g, &b);

            draw_vline(screen, x, height_screen, screen->ybuffer[x], r, g, b);

            if(height_screen < screen->ybuffer[x]) {
                screen->ybuffer[x] = height_screen;
            }

            point_left.x += dx;
            point_left.y += dy;
        }

        z += dz;
        dz += PRECISION;
    }
}

int main(int args, char *argv[]) {
    (void)args;
    (void)argv;

    if(SDL_Init(SDL_INIT_VIDEO) < 0) {
        perror("SDL_Init");
        return -1;
    }

    if(IMG_Init(IMG_INIT_PNG) < 0) {
        perror("IMG_Init");
        return -1;
    }

    SDL_Window *window;
    SDL_Renderer *renderer;

    window = SDL_CreateWindow("comanche" , SDL_WINDOWPOS_CENTERED , SDL_WINDOWPOS_CENTERED , SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    if(window == NULL) {
        perror("SDL_CreateWindow");
        return EXIT_FAILURE;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if(renderer == NULL)  {
        perror("SDL_CreateRenderer");
        return EXIT_FAILURE;
    }


    struct map_t map = {
        .width = 1024,
        .height = 1024,
        .shift = 1023
    };

    struct screen_t screen = {
        .renderer = renderer,

        .width = SCREEN_WIDTH,
        .height = SCREEN_HEIGHT 
    };

    struct camera_t camera = {
        .position = {512,512},
        .angle = 0.0f,
        .distance = 6400.0f,
        .height = 100.0f,
        .horizon = 100
    };

    SDL_Texture *texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, screen.width, screen.height);
    load_map(&map, 0);

    FPSmanager fps_manager;

    SDL_initFramerate(&fps_manager);
    SDL_setFramerate(&fps_manager, 60);

    SDL_bool done = SDL_FALSE;

    int level_number = 1;

    int saved_x = 0, saved_y = 0;
    int x = saved_x,y = saved_y;

    uint64_t now = SDL_GetPerformanceCounter();
    uint64_t last = 0.0f;
    float delta_time = 0.0f;
    float vel = 0.0f;

    while (!done) {
        last = now;
        now = SDL_GetPerformanceCounter();

        delta_time = ((now - last)*1000.0f / (float)SDL_GetPerformanceFrequency()) / 1000.0f;

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            switch( event.type ){
            case SDL_QUIT:
                done = SDL_TRUE;
                break;
            case SDL_KEYDOWN:
                switch( event.key.keysym.sym ){
                    case SDLK_w:
                    case SDLK_z:
                        vel += 0.3f;
                        camera.height += camera.horizon * 0.25 * delta_time;
                        camera.position.x -= sin(camera.angle) * CAMERA_SPEED * delta_time;
                        camera.position.y -= cos(camera.angle) * CAMERA_SPEED * delta_time;
                        break;
                    case SDLK_s:
                        vel -= 0.2f;
                        camera.height -= camera.horizon * 0.25 * delta_time;
                        camera.position.x += sin(camera.angle) * CAMERA_SPEED * delta_time;
                        camera.position.y += cos(camera.angle) * CAMERA_SPEED * delta_time;
                        break;
                    case SDLK_n:
                        ++level_number;
                        if(level_number > 24)
                            level_number = 0;
                        load_map(&map, level_number);
                        break;
                    case SDLK_p:
                        --level_number;
                        if(level_number < 0)
                            level_number = 24;
                        load_map(&map, level_number);
                        break;
                    default:
                        printf("delta_time: %f\n", delta_time);
                        break;
                }
                break;
            case SDL_MOUSEMOTION: {
                x = event.motion.x;
                y = event.motion.y;
            }
                break;
            }
        }

        vel -= 0.15f;

        if(vel < 0.0f)
            vel = 0.0f;

        camera.position.x -= vel * sin(camera.angle);
        camera.position.y -= vel * cos(camera.angle);

        float delta_y = (y - screen.height/2.0) / 2; 
        float delta_x = (x - screen.width/2.0) / 3;

        if(abs(delta_x) > DEADZONE || abs(delta_y) > DEADZONE ) {
            camera.angle -= delta_x / screen.width * delta_time * 5;
            camera.horizon -= delta_y / screen.height * delta_time * 3500;

            if(camera.horizon < -520.0f) {
                camera.horizon = -520.0f;
            }
            else if(camera.horizon > 520.0f) {
                camera.horizon = 520.0f;
            }
        }

        render(&screen, &camera, &map, 900.0f);

        SDL_UpdateTexture(texture, NULL, screen.buffer, screen.width * 3);
        SDL_RenderCopy(screen.renderer, texture, NULL, NULL);

        SDL_RenderPresent(screen.renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    SDL_FreeSurface(map.img_heightmap);
    SDL_FreeSurface(map.img_colormap);

    free(map.heightmap);
    free(map.colormap);

    IMG_Quit();
    SDL_Quit();

    return 0;
}
```
