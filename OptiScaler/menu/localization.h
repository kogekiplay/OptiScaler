#pragma once

#include <Config.h>

#include <imgui/imgui.h>

#include <array>
#include <cstdarg>
#include <filesystem>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace MenuLocalization
{
struct Translation
{
    std::string_view source;
    std::string_view zhCn;
};

inline constexpr Translation translations[] = {
#include "translations_zh_cn_core.inc"
#include "translations_zh_cn_1.inc"
#include "translations_zh_cn_2.inc"
#include "translations_zh_cn_3.inc"
};

inline bool IsSimplifiedChinese()
{
    const auto config = Config::Instance();
    if (!config->MenuLanguage.has_value())
        return true;

    const auto& language = config->MenuLanguage.value();
    return language == "zh-CN" || language == "zh-cn" || language == "zh_CN" || language == "zh_cn" ||
           language == "Chinese" || language == "chinese";
}

inline const std::unordered_map<std::string_view, std::string_view>& ZhCnMap()
{
    static const auto result = []
    {
        std::unordered_map<std::string_view, std::string_view> map;
        map.reserve(sizeof(translations) / sizeof(translations[0]));

        for (const auto& entry : translations)
            map.emplace(entry.source, entry.zhCn);

        return map;
    }();

    return result;
}

inline std::string& ScratchBuffer()
{
    thread_local std::array<std::string, 32> buffers;
    thread_local size_t index = 0;
    index = (index + 1) % buffers.size();
    buffers[index].clear();
    return buffers[index];
}

inline std::string_view TranslateView(std::string_view source)
{
    if (!IsSimplifiedChinese() || source.empty())
        return source;

    const auto& map = ZhCnMap();

    if (const auto it = map.find(source); it != map.end())
        return it->second;

    const auto hiddenId = source.find("##");
    if (hiddenId != std::string_view::npos && hiddenId > 0)
    {
        const auto visible = source.substr(0, hiddenId);
        if (const auto it = map.find(visible); it != map.end())
            return it->second;
    }

    return source;
}

// Plain display text. If a translated string has an ImGui hidden suffix, retain it.
inline const char* TranslateText(const char* source)
{
    if (source == nullptr || !IsSimplifiedChinese())
        return source;

    const std::string_view original(source);
    const auto translated = TranslateView(original);
    if (translated.data() == original.data() && translated.size() == original.size())
        return source;

    const auto hiddenId = original.find("##");
    if (hiddenId == std::string_view::npos)
        return translated.data();

    auto& result = ScratchBuffer();
    result.assign(translated);
    result.append(original.substr(hiddenId));
    return result.c_str();
}

// Interactive labels use ### so changing languages never changes the ImGui ID.
inline const char* TranslateLabel(const char* source)
{
    if (source == nullptr || !IsSimplifiedChinese())
        return source;

    const std::string_view original(source);
    if (original.starts_with("##"))
        return source;

    const auto translated = TranslateView(original);
    if (translated.data() == original.data() && translated.size() == original.size())
        return source;

    auto& result = ScratchBuffer();
    result.assign(translated);
    result.append("###");
    result.append(original);
    return result.c_str();
}

inline std::wstring FindCjkFontPath()
{
    static const std::wstring result = []() -> std::wstring
    {
        std::vector<std::filesystem::path> roots;

        wchar_t windowsDir[MAX_PATH] {};
        if (GetWindowsDirectoryW(windowsDir, MAX_PATH) > 0)
            roots.emplace_back(std::filesystem::path(windowsDir) / L"Fonts");

        wchar_t localAppData[MAX_PATH] {};
        if (GetEnvironmentVariableW(L"LOCALAPPDATA", localAppData, MAX_PATH) > 0)
            roots.emplace_back(std::filesystem::path(localAppData) / L"Microsoft" / L"Windows" / L"Fonts");

        constexpr std::array candidates = { L"msyh.ttc",
                                            L"msyhbd.ttc",
                                            L"simhei.ttf",
                                            L"simsun.ttc",
                                            L"Deng.ttf",
                                            L"Dengb.ttf",
                                            L"NotoSansSC-Regular.otf",
                                            L"NotoSansCJK-Regular.ttc" };

        std::error_code error;
        for (const auto& root : roots)
        {
            for (const auto* candidate : candidates)
            {
                const auto path = root / candidate;
                if (std::filesystem::exists(path, error))
                    return path.wstring();
                error.clear();
            }
        }

        return {};
    }();

    return result;
}
} // namespace MenuLocalization

// The wrappers below let menu_common.cpp localize existing ImGui calls through
// a small set of token redirects. English source strings remain untouched,
// keeping future upstream merges manageable.
namespace ImGui
{
inline bool LocalizedBegin(const char* name, bool* pOpen = nullptr, ImGuiWindowFlags flags = 0)
{
    return Begin(MenuLocalization::TranslateLabel(name), pOpen, flags);
}

inline bool LocalizedBeginCombo(const char* label, const char* previewValue, ImGuiComboFlags flags = 0)
{
    return BeginCombo(MenuLocalization::TranslateLabel(label), MenuLocalization::TranslateText(previewValue), flags);
}

inline bool LocalizedButton(const char* label, const ImVec2& size = ImVec2(0, 0))
{
    return Button(MenuLocalization::TranslateLabel(label), size);
}

inline bool LocalizedCheckbox(const char* label, bool* value)
{
    return Checkbox(MenuLocalization::TranslateLabel(label), value);
}

inline bool LocalizedCheckboxFlags(const char* label, int* flags, int flagsValue)
{
    return CheckboxFlags(MenuLocalization::TranslateLabel(label), flags, flagsValue);
}

inline bool LocalizedCheckboxFlags(const char* label, unsigned int* flags, unsigned int flagsValue)
{
    return CheckboxFlags(MenuLocalization::TranslateLabel(label), flags, flagsValue);
}

inline bool LocalizedColorEdit3(const char* label, float color[3], ImGuiColorEditFlags flags = 0)
{
    return ColorEdit3(MenuLocalization::TranslateLabel(label), color, flags);
}

inline bool LocalizedCombo(const char* label, int* currentItem, const char* const items[], int itemCount,
                           int popupMaxHeightInItems = -1)
{
    std::vector<const char*> localizedItems;
    localizedItems.reserve(itemCount);
    for (int i = 0; i < itemCount; ++i)
        localizedItems.push_back(MenuLocalization::TranslateText(items[i]));

    return Combo(MenuLocalization::TranslateLabel(label), currentItem, localizedItems.data(), itemCount,
                 popupMaxHeightInItems);
}

inline bool LocalizedInputFloat(const char* label, float* value, float step = 0.0f, float stepFast = 0.0f,
                                const char* format = "%.3f", ImGuiInputTextFlags flags = 0)
{
    return InputFloat(MenuLocalization::TranslateLabel(label), value, step, stepFast,
                      MenuLocalization::TranslateText(format), flags);
}

inline bool LocalizedInputInt(const char* label, int* value, int step = 1, int stepFast = 100,
                              ImGuiInputTextFlags flags = 0)
{
    return InputInt(MenuLocalization::TranslateLabel(label), value, step, stepFast, flags);
}

inline bool LocalizedInputScalar(const char* label, ImGuiDataType dataType, void* data, const void* step = nullptr,
                                 const void* stepFast = nullptr, const char* format = nullptr,
                                 ImGuiInputTextFlags flags = 0)
{
    return InputScalar(MenuLocalization::TranslateLabel(label), dataType, data, step, stepFast,
                       MenuLocalization::TranslateText(format), flags);
}

inline void LocalizedPlotLines(const char* label, const float* values, int valuesCount, int valuesOffset = 0,
                               const char* overlayText = nullptr, float scaleMin = FLT_MAX, float scaleMax = FLT_MAX,
                               ImVec2 graphSize = ImVec2(0, 0), int stride = sizeof(float))
{
    PlotLines(MenuLocalization::TranslateLabel(label), values, valuesCount, valuesOffset,
              MenuLocalization::TranslateText(overlayText), scaleMin, scaleMax, graphSize, stride);
}

inline void LocalizedPlotLines(const char* label, float (*valuesGetter)(void* data, int index), void* data,
                               int valuesCount, int valuesOffset = 0, const char* overlayText = nullptr,
                               float scaleMin = FLT_MAX, float scaleMax = FLT_MAX, ImVec2 graphSize = ImVec2(0, 0))
{
    PlotLines(MenuLocalization::TranslateLabel(label), valuesGetter, data, valuesCount, valuesOffset,
              MenuLocalization::TranslateText(overlayText), scaleMin, scaleMax, graphSize);
}

inline bool LocalizedRadioButton(const char* label, bool active)
{
    return RadioButton(MenuLocalization::TranslateLabel(label), active);
}

inline bool LocalizedRadioButton(const char* label, int* value, int valueButton)
{
    return RadioButton(MenuLocalization::TranslateLabel(label), value, valueButton);
}

inline bool LocalizedSelectable(const char* label, bool selected = false, ImGuiSelectableFlags flags = 0,
                                const ImVec2& size = ImVec2(0, 0))
{
    return Selectable(MenuLocalization::TranslateLabel(label), selected, flags, size);
}

inline bool LocalizedSelectable(const char* label, bool* selected, ImGuiSelectableFlags flags = 0,
                                const ImVec2& size = ImVec2(0, 0))
{
    return Selectable(MenuLocalization::TranslateLabel(label), selected, flags, size);
}

inline void LocalizedSeparatorText(const char* label) { SeparatorText(MenuLocalization::TranslateText(label)); }

inline void LocalizedSetTooltip(const char* format, ...)
{
    va_list args;
    va_start(args, format);
    SetTooltipV(MenuLocalization::TranslateText(format), args);
    va_end(args);
}

inline bool LocalizedSliderFloat(const char* label, float* value, float minimum, float maximum,
                                 const char* format = "%.3f", ImGuiSliderFlags flags = 0)
{
    return SliderFloat(MenuLocalization::TranslateLabel(label), value, minimum, maximum,
                       MenuLocalization::TranslateText(format), flags);
}

inline bool LocalizedSliderInt(const char* label, int* value, int minimum, int maximum, const char* format = "%d",
                               ImGuiSliderFlags flags = 0)
{
    return SliderInt(MenuLocalization::TranslateLabel(label), value, minimum, maximum,
                     MenuLocalization::TranslateText(format), flags);
}

inline void LocalizedTableSetupColumn(const char* label, ImGuiTableColumnFlags flags = 0,
                                      float initialWidthOrWeight = 0.0f, ImGuiID userId = 0)
{
    TableSetupColumn(MenuLocalization::TranslateLabel(label), flags, initialWidthOrWeight, userId);
}

inline void LocalizedText(const char* format, ...)
{
    va_list args;
    va_start(args, format);
    TextV(MenuLocalization::TranslateText(format), args);
    va_end(args);
}

inline void LocalizedTextColored(const ImVec4& color, const char* format, ...)
{
    va_list args;
    va_start(args, format);
    TextColoredV(color, MenuLocalization::TranslateText(format), args);
    va_end(args);
}

inline void LocalizedTextDisabled(const char* format, ...)
{
    va_list args;
    va_start(args, format);
    TextDisabledV(MenuLocalization::TranslateText(format), args);
    va_end(args);
}

inline void LocalizedTextWrapped(const char* format, ...)
{
    va_list args;
    va_start(args, format);
    TextWrappedV(MenuLocalization::TranslateText(format), args);
    va_end(args);
}

inline void LocalizedTextLinkOpenURL(const char* label, const char* url = nullptr)
{
    TextLinkOpenURL(MenuLocalization::TranslateLabel(label), url);
}

inline bool LocalizedTreeNode(const char* label) { return TreeNode(MenuLocalization::TranslateLabel(label)); }

inline ImVec2 LocalizedCalcTextSize(const char* text, const char* textEnd = nullptr,
                                    bool hideTextAfterDoubleHash = false, float wrapWidth = -1.0f)
{
    if (textEnd != nullptr)
        return CalcTextSize(text, textEnd, hideTextAfterDoubleHash, wrapWidth);

    return CalcTextSize(MenuLocalization::TranslateText(text), nullptr, hideTextAfterDoubleHash, wrapWidth);
}
} // namespace ImGui
