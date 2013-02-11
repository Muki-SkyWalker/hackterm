
#import "SDLUIApplication.h"
#import <objc/runtime.h>
#include "../../events/SDL_keyboard_c.h"

#define GSEVENT_TYPE 2
#define GSEVENT_FLAGS 12
#define GSEVENTKEY_KEYCODE    15
#define GSEVENT_TYPE_KEYDOWN  10
#define GSEVENT_TYPE_KEYUP    11
#define GSEVENT_TYPE_MODKEY   12

@implementation SDLUIApplication

int modset_ralt  = 0;
int modset_lctrl = 0;
int modset_lalt  = 0;
int modset_lcmd  = 0;
int modset_rcmd  = 0;

#define MODCODE1_RALT  64
#define MODCODE1_LCTRL 16
#define MODCODE1_LALT  8
#define MODCODE1_LCMD  1
#define MODCODE2_RCMD  1

void dump_modkeys() {
    printf("modkeys\n");
    if(modset_ralt  == 1) {printf("ralt  pressed\n");}
    if(modset_lctrl == 1) {printf("rctrl pressed\n");}
    if(modset_lalt  == 1) {printf("lalt  pressed\n");}
    if(modset_lcmd  == 1) {printf("lcmd  pressed\n");}
    if(modset_rcmd  == 1) {printf("rcmd  pressed\n");}
}

bool any_modkey() {
    if(modset_ralt  == 1) return true;
    if(modset_lctrl == 1) return true;
    if(modset_lalt  == 1) return true;
    if(modset_lcmd  == 1) return true;
    if(modset_rcmd  == 1) return true;
    
    return false;
}

int lookup_scancode(int code) {
    return code;
}

void check_code(int keymod,int keymask,int *key) {
//    printf("key: %d %d\n",keymod,keymask);
    if(keymod & keymask) {
//        printf("registrying press\n");
        SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_RALT);
        *key=1;
    } else {
        if(*key == 1) {
//            printf("registering release\n");
            SDL_SendKeyboardKey(SDL_RELEASED, SDL_SCANCODE_RALT);
            *key=0;
        }
    }
}

- (void)sendEvent:(UIEvent *)event {

    [super sendEvent:event];

    if ([event respondsToSelector:@selector(_gsEvent)]) {
        
        unsigned char *eventMem;
        eventMem = (unsigned char *)[event performSelector:@selector(_gsEvent)];
        if (eventMem) {
            int eventType = eventMem[8];
            int keycode   = eventMem[60];
            int keymod1   = eventMem[50];
            int keymod2   = eventMem[51];

            check_code(keymod1,MODCODE1_RALT ,&modset_ralt);
            check_code(keymod1,MODCODE1_LCTRL,&modset_lctrl);
            check_code(keymod1,MODCODE1_LALT ,&modset_lalt);
            check_code(keymod1,MODCODE1_LCMD ,&modset_lcmd);
            check_code(keymod2,MODCODE2_RCMD ,&modset_rcmd);
            dump_modkeys();
            
            // if any modifier key is pressed, then we need to send normal keypressed, otherwise
            // they are handled by the UITextField which takes keyboard language into account,
            // and works with the virtual keyboard.
            if(modset_lctrl == 1) {
                int sdl_scancode = lookup_scancode(keycode);
                if(eventType == GSEVENT_TYPE_KEYDOWN) {
                    char text[5];
                    text[0] = keycode-4+1;
                    text[1] = 0;
                    SDL_SendKeyboardKey(SDL_PRESSED,sdl_scancode);
                    SDL_SendKeyboardText(text);
                }
                
                if(eventType == GSEVENT_TYPE_KEYUP) {
                    SDL_SendKeyboardKey(SDL_RELEASED,sdl_scancode);
                }
            }
            
            printf("event type is: %u\n",eventType);
            if ((eventType == GSEVENT_TYPE_KEYDOWN) && (keycode == 41)) {
                SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_ESCAPE);
            } else
            if ((eventType == GSEVENT_TYPE_KEYUP  ) && (keycode == 41)) {
                SDL_SendKeyboardKey(SDL_RELEASED, SDL_SCANCODE_ESCAPE);
                char text[5];
                text[0] = 27;
                text[1] = 0;
                SDL_SendKeyboardText(text);
            } else
            if ((eventType == GSEVENT_TYPE_KEYDOWN) && (keycode == 3 )) {
                SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_MODE);
            } else
            if ((eventType == GSEVENT_TYPE_KEYUP  ) && (keycode == 3 )) {
                SDL_SendKeyboardKey(SDL_RELEASED, SDL_SCANCODE_MODE);
            } else
            {
                printf("keycode %u\n",keycode);
//                printf("keymod1 %u\n",keymod1);
//                printf("keymod2 %u\n",keymod2);
            }
        }
    }
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    printf("here in sendAction");
//    return NO;
    return [super sendAction:action to:target from:sender forEvent:event];
}

@end