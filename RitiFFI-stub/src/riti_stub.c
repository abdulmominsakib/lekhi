/*
 * RitiFFI stub implementation — provides empty/no-op symbols so the
 * Swift code can compile and link. Transliteration calls will return
 * empty suggestions until the real Rust-built framework is dropped in.
 *
 * Once `scripts/build_xcframework.sh` produces the real
 * `RitiFFI.xcframework`, this stub should be removed.
 */

#include "avrobangla_engine.h"
#include <stdlib.h>
#include <string.h>

struct Config { int dummy; };
struct RitiContext { int dummy; };
struct Suggestion {
    char *lonely;
    char **items;
    size_t length;
    size_t previous;
    bool is_lonely;
};

/* Config */
struct Config *riti_config_new(void) {
    struct Config *c = (struct Config *)calloc(1, sizeof(struct Config));
    return c;
}
void riti_config_free(struct Config *ptr) { free(ptr); }
bool riti_config_set_layout_file(struct Config *ptr, const char *path) { (void)ptr; (void)path; return true; }
bool riti_config_set_database_dir(struct Config *ptr, const char *path) { (void)ptr; (void)path; return true; }
bool riti_config_set_user_dir(struct Config *ptr, const char *path) { (void)ptr; (void)path; return true; }
void riti_config_set_suggestion_include_english(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_phonetic_suggestion(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_suggestion(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_auto_vowel(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_auto_chandra(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_traditional_kar(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_old_reph(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_numpad(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_fixed_old_kar_order(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_ansi_encoding(struct Config *ptr, bool option) { (void)ptr; (void)option; }
void riti_config_set_smart_quote(struct Config *ptr, bool option) { (void)ptr; (void)option; }

/* Context */
struct RitiContext *riti_context_new_with_config(const struct Config *ptr) {
    (void)ptr;
    struct RitiContext *c = (struct RitiContext *)calloc(1, sizeof(struct RitiContext));
    return c;
}
void riti_context_free(struct RitiContext *ptr) { free(ptr); }
bool riti_context_ongoing_input_session(struct RitiContext *ptr) { (void)ptr; return false; }
void riti_context_finish_input_session(struct RitiContext *ptr) { (void)ptr; }
void riti_context_candidate_committed(struct RitiContext *ptr, uintptr_t index) { (void)ptr; (void)index; }
void riti_context_update_engine(struct RitiContext *ptr, const struct Config *config) { (void)ptr; (void)config; }
struct Suggestion *riti_context_backspace_event(struct RitiContext *ptr, bool ctrl) {
    (void)ptr; (void)ctrl;
    struct Suggestion *s = (struct Suggestion *)calloc(1, sizeof(struct Suggestion));
    s->is_lonely = true;
    return s;
}
struct Suggestion *riti_get_suggestion_for_key(struct RitiContext *ptr,
                                                uint16_t key,
                                                uint8_t modifier,
                                                uint8_t selection) {
    (void)ptr; (void)key; (void)modifier; (void)selection;
    /* For the stub, return a lonely empty suggestion so the keyboard
     * simply falls through to its English input path. */
    struct Suggestion *s = (struct Suggestion *)calloc(1, sizeof(struct Suggestion));
    s->is_lonely = true;
    return s;
}

/* Suggestion */
void riti_suggestion_free(struct Suggestion *ptr) {
    if (!ptr) return;
    if (ptr->lonely) free(ptr->lonely);
    if (ptr->items) {
        for (size_t i = 0; i < ptr->length; i++) free(ptr->items[i]);
        free(ptr->items);
    }
    free(ptr);
}
char *riti_suggestion_get_suggestion(const struct Suggestion *ptr, uintptr_t index) {
    if (!ptr || index >= ptr->length || !ptr->items) return NULL;
    return strdup(ptr->items[index]);
}
char *riti_suggestion_get_lonely_suggestion(const struct Suggestion *ptr) {
    if (!ptr || !ptr->lonely) return NULL;
    return strdup(ptr->lonely);
}
char *riti_suggestion_get_auxiliary_text(const struct Suggestion *ptr) {
    (void)ptr; return strdup("");
}
char *riti_suggestion_get_pre_edit_text(const struct Suggestion *ptr, uintptr_t index) {
    (void)ptr; (void)index; return strdup("");
}
void riti_string_free(char *ptr) { free(ptr); }
uintptr_t riti_suggestion_previously_selected_index(const struct Suggestion *ptr) { (void)ptr; return 0; }
uintptr_t riti_suggestion_get_length(const struct Suggestion *ptr) { (void)ptr; return 0; }
bool riti_suggestion_is_lonely(const struct Suggestion *ptr) {
    if (!ptr) return false;
    return ptr->is_lonely;
}
bool riti_suggestion_is_empty(const struct Suggestion *ptr) {
    if (!ptr) return true;
    return ptr->length == 0 && (ptr->lonely == NULL);
}

/* Keycode mapping (matches the Rust upstream 1:1) */
uint16_t avro_keycode_for_char(uint32_t ch) {
    switch (ch) {
        case 'a': case 'A': return 41110;
        case 'b': return 41111;
        case 'c': return 41112;
        case 'd': return 41113;
        case 'e': return 41114;
        case 'f': return 41115;
        case 'g': return 41116;
        case 'h': return 41117;
        case 'i': return 41118;
        case 'j': return 41119;
        case 'k': return 41120;
        case 'l': return 41121;
        case 'm': return 41122;
        case 'n': return 41123;
        case 'o': return 41124;
        case 'p': return 41125;
        case 'q': return 41126;
        case 'r': return 41127;
        case 's': return 41128;
        case 't': return 41129;
        case 'u': return 41130;
        case 'v': return 41131;
        case 'w': return 41132;
        case 'x': return 41133;
        case 'y': return 41134;
        case 'z': return 41135;
        default: return 0;
    }
}
