#pragma once

#include <regex>

// Use the same syntax and flags for validation and track selection.
class TrackPreference
{
    bool m_enabled;
    std::wregex m_regex;

public:
    explicit TrackPreference(const wchar_t* pattern)
        : m_enabled(pattern && *pattern)
        , m_regex(pattern ? pattern : L"", std::regex_constants::ECMAScript | std::regex_constants::icase)
    {
    }

    bool Matches(const wchar_t* name) const
    {
        return m_enabled && name && std::regex_search(name, m_regex);
    }
};
