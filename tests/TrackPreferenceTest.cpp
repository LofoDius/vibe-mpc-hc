#include "../src/mpc-hc/TrackPreference.h"
#include <cassert>
int main() {
    assert(TrackPreference(L"english").Matches(L"Audio 2 [English] (AAC)"));
    assert(TrackPreference(L"Studio.*5\\.1").Matches(L"Japanese - Studio dub 5.1"));
    assert(!TrackPreference(L"^English$").Matches(L"English [forced]"));
    assert(TrackPreference(L"^English$").Matches(L"ENGLISH"));
    assert(!TrackPreference(L"").Matches(L"English"));
    assert(TrackPreference(L"[0-9]{2,3}").Matches(L"Track 123"));
    assert(TrackPreference(L"English|Japanese").Matches(L"Japanese"));
    bool invalid = false;
    try { TrackPreference p(L"["); } catch (const std::regex_error&) { invalid = true; }
    assert(invalid);
}
