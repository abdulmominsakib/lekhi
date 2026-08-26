/*
 * RitiFFI stub — minimal placeholder so the Swift code can compile
 * before the real Rust staticlib has been built. The real
 * implementation is produced by `scripts/build_xcframework.sh`.
 */

#ifndef RITI_H_STUB
#define RITI_H_STUB

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct Config Config;
typedef struct RitiContext RitiContext;
typedef struct Suggestion Suggestion;

struct RitiContext *riti_context_new_with_config(const struct Config *ptr);
void riti_context_free(struct RitiContext *ptr);
struct Suggestion *riti_get_suggestion_for_key(struct RitiContext *ptr,
                                                uint16_t key,
                                                uint8_t modifier,
                                                uint8_t selection);
void riti_context_candidate_committed(struct RitiContext *ptr, uintptr_t index);
void riti_context_update_engine(struct RitiContext *ptr, const struct Config *config);
bool riti_context_ongoing_input_session(struct RitiContext *ptr);
void riti_context_finish_input_session(struct RitiContext *ptr);
struct Suggestion *riti_context_backspace_event(struct RitiContext *ptr, bool ctrl);
void riti_suggestion_free(struct Suggestion *ptr);
char *riti_suggestion_get_suggestion(const struct Suggestion *ptr, uintptr_t index);
char *riti_suggestion_get_lonely_suggestion(const struct Suggestion *ptr);
char *riti_suggestion_get_auxiliary_text(const struct Suggestion *ptr);
char *riti_suggestion_get_pre_edit_text(const struct Suggestion *ptr, uintptr_t index);
void riti_string_free(char *ptr);
uintptr_t riti_suggestion_previously_selected_index(const struct Suggestion *ptr);
uintptr_t riti_suggestion_get_length(const struct Suggestion *ptr);
bool riti_suggestion_is_lonely(const struct Suggestion *ptr);
bool riti_suggestion_is_empty(const struct Suggestion *ptr);

struct Config *riti_config_new(void);
void riti_config_free(struct Config *ptr);
bool riti_config_set_layout_file(struct Config *ptr, const char *path);
bool riti_config_set_database_dir(struct Config *ptr, const char *path);
bool riti_config_set_user_dir(struct Config *ptr, const char *path);
void riti_config_set_suggestion_include_english(struct Config *ptr, bool option);
void riti_config_set_phonetic_suggestion(struct Config *ptr, bool option);
void riti_config_set_fixed_suggestion(struct Config *ptr, bool option);
void riti_config_set_fixed_auto_vowel(struct Config *ptr, bool option);
void riti_config_set_fixed_auto_chandra(struct Config *ptr, bool option);
void riti_config_set_fixed_traditional_kar(struct Config *ptr, bool option);
void riti_config_set_fixed_old_reph(struct Config *ptr, bool option);
void riti_config_set_fixed_numpad(struct Config *ptr, bool option);
void riti_config_set_fixed_old_kar_order(struct Config *ptr, bool option);
void riti_config_set_ansi_encoding(struct Config *ptr, bool option);
void riti_config_set_smart_quote(struct Config *ptr, bool option);

uint16_t avro_keycode_for_char(uint32_t ch);

#endif /* RITI_H_STUB */
