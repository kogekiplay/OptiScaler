# OptiScaler 简体中文 fork

这是 [OptiScaler](https://github.com/optiscaler/OptiScaler) 的简体中文本地化 fork。核心功能、兼容性和安装方式仍以上游项目为准；本 fork 主要维护中文游戏内菜单和自动构建。

## 下载

- [简体中文 Nightly（未签名）](https://github.com/kogekiplay/OptiScaler/releases/tag/nightly-zh-cn)
- 每天北京时间约 04:23 自动构建，也可以通过 GitHub Actions 手动触发。
- 发布包同时提供 `.sha256` 文件，可用于校验下载内容。

Nightly 是自动生成的开发版本，不带本 fork 的代码签名。Windows 或安全软件可能显示未知发布者提示。

## 语言和字体

本 fork 默认使用简体中文。可以在 `OptiScaler.ini` 中切换：

```ini
[Menu]
Language=zh-CN
```

可选值：

- `zh-CN`：简体中文
- `en-US`：英文

中文模式会优先加载 Windows 自带的微软雅黑、黑体、宋体或等线字体。如果菜单显示方框，请保持 `UseHQFont=true`，并手动指定一个包含中文字形的字体，例如：

```ini
[Menu]
UseHQFont=true
TTFFontPath=C:\Windows\Fonts\msyh.ttc
```

## 安装与使用

安装步骤、受支持的 API/超分算法和已知问题请参考：

- [上游英文 README](README.md)
- [上游 Wiki](https://github.com/optiscaler/OptiScaler/wiki)

解压发布包后，请先完整阅读包内说明和上游安装文档。不要在源码目录中运行 `setup_windows.bat`；它是面向游戏目录的安装脚本，不是源码构建脚本。

## 从源码构建

需要 Visual Studio 2022、MSVC v143、Windows SDK 和全部 git submodule：

```powershell
git submodule update --init --recursive
msbuild .\OptiScaler.sln /m /t:Build /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
```

构建后的发布目录为 `x64\Release\a\`。

## 上游同步

本地仓库建议保留两个 remote：

```text
origin    https://github.com/kogekiplay/OptiScaler.git
upstream  https://github.com/optiscaler/OptiScaler.git
```

本 fork 会尽量保持英文原文作为本地化键；上游新增但尚未翻译的文本会自动回退为英文。
