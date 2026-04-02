# 小天气 (Small Weather)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)

**小天气** 是一款基于 Flutter 开发的简约、精致的拟物化（Neumorphism）天气预报应用。它不仅提供实时的天气数据和详细的预报，还通过高度可定制的 UI 界面，为用户带来独特的操作体验。

## ✨ 主要功能

- 🌦️ **实时天气**：获取当前位置或全球任意城市的实时天气及空气质量。
- 📅 **多维预报**：提供未来 24 小时逐小时预报及未来 7 天逐日预报。
- 📍 **城市中心**：支持自动定位及手动添加/管理多个城市。
- 👤 **用户系统**：支持账号注册、登录及密码修改。登录后可跨设备同步您的城市列表与个性化设置。
- 🎨 **拟物化视觉**：
  - **极致拟物（Neumorphism）**：通过精心调校的阴影与光效，打造充满质感的界面。
  - **动态光影**：用户可自定义光源角度（Light Angle）与阴影强度（Shadow Intensity）。
  - **深色模式**：完美支持深色与浅色模式。
- 🌐 **多语言支持**：内置简体中文与英文支持。

## 🛠️ 技术栈

- **框架**: [Flutter](https://flutter.dev/) (SDK ^3.10.7)
- **状态管理**: [Provider](https://pub.dev/packages/provider)
- **网络层**: [Dio](https://pub.dev/packages/dio) (拦截器实现 Auth Token 管理)
- **本地存储**: [Shared Preferences](https://pub.dev/packages/shared_preferences) (持久化配置与缓存)
- **数据可视化**: [FL Chart](https://pub.dev/packages/fl_chart) (气温趋势图)
- **多媒体**: [Image Picker](https://pub.dev/packages/image_picker) & [Image Cropper](https://pub.dev/packages/image_cropper) (用户头像处理)
- **云服务**: [Tencent Cloud COS](https://cloud.tencent.com/product/cos) (用户资源存储)
- **字体与图标**: 
  - Google Fonts (Inter)
  - QWeather Icons (和风天气自定义图标库)

## 🚀 快速开始

### 环境依赖

- Flutter SDK: `^3.10.7`
- Dart SDK: `^3.0.0`

### 安装与运行

1. 克隆仓库：
   ```bash
   git clone <repository-url>
   cd weather-app
   ```

2. 获取依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run
   ```

4. **[重要] iOS 签名配置**：
   在真机或正式环境下构建 iOS 应用，需配置 Apple Developer Team：
   - 打开 Xcode 项目：`open ios/Runner.xcworkspace`
   - 在 `Runner` 目标的 `Signing & Capabilities` 中选择您的 `Team`。
   - 确保 `Bundle Identifier` 为唯一标识。

## 📁 项目结构

```text
lib/
├── assets/             # 静态资源 (字体、图标、Logo)
├── main.dart           # 应用入口
├── providers/          # 业务逻辑与状态管理 (AppProvider)
├── screens/            # UI 界面 (Home, Forecast, Settings, Auth 等)
├── services/           # 网络请求 (ApiService) 与位置服务 (LocationService)
├── theme/              # 拟物化主题定义 (NeuTheme)
├── utils/              # 工具函数
└── widgets/           # 复用组件 (NeuCard, WeatherIcon, etc.)
```

## 📝 许可证

本项目基于 [MIT License](LICENSE)（如有）或遵循开发者个人声明。

---
*制作：[Pencil Gallery](https://github.com/pencil-gallery)*
