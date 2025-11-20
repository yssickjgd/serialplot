# SerialPlot src/ 目录代码组织

## 目录说明

本文档详细列出src/目录下所有源代码文件，并按功能模块进行分类整理。

---

## 📁 模块一：数据流核心 (Data Flow Core)

### 1.1 源和汇抽象 (Source-Sink Abstraction)

#### source.h / source.cpp
**作用**: 数据源基类
- 定义数据生产者的接口
- 管理连接的Sink列表
- 实现`feedOut()`方法向Sink发送数据
- 实现`connectSink()`, `disconnect()`, `disconnectSinks()`等连接管理方法

**关键接口**:
```cpp
virtual bool hasX() const = 0;
virtual unsigned numChannels() const = 0;
void connectSink(Sink* sink);
void feedOut(const SamplePack& data);
```

#### sink.h / sink.cpp
**作用**: 数据汇基类
- 定义数据消费者的接口
- 支持follower机制（链式连接）
- 管理连接的Source

**关键接口**:
```cpp
virtual void feedIn(const SamplePack& data);
virtual void setNumChannels(unsigned nc, bool x);
void connectFollower(Sink* sink);
```

#### samplepack.h / samplepack.cpp
**作用**: 数据包封装类
- 封装传输的样本数据
- 包含通道数、样本数信息
- 提供数据访问接口

---

### 1.2 数据读取器 (Readers)

#### abstractreader.h / abstractreader.cpp
**作用**: 所有读取器的抽象基类
- 继承自`Source`接口
- 从`QIODevice`读取数据
- 定义读取器的通用行为

**关键方法**:
```cpp
virtual QWidget* settingsWidget() = 0;  // 设置界面
virtual void enable(bool enabled = true);  // 启用/禁用
void pause(bool enabled);  // 暂停
virtual unsigned readData() = 0;  // 纯虚函数：读取数据
```

**子类实现**:

1. **binarystreamreader.h / binarystreamreader.cpp**
   - 读取二进制数据流
   - 支持: (u)int8, (u)int16, (u)int32, float
   - 支持大小端设置
   - 连续数据流处理

2. **binarystreamreadersettings.h / binarystreamreadersettings.cpp / binarystreamreadersettings.ui**
   - 二进制流读取器的设置界面
   - 配置数据类型、字节序、通道数

3. **asciireader.h / asciireader.cpp**
   - 读取ASCII文本数据
   - 支持CSV格式（逗号分隔）
   - 每行一组样本

4. **asciireadersettings.h / asciireadersettings.cpp / asciireadersettings.ui**
   - ASCII读取器的设置界面
   - 配置分隔符、通道数

5. **framedreader.h / framedreader.cpp**
   - 读取帧格式数据
   - 支持自定义帧头、帧尾
   - 支持校验和验证
   - 更鲁棒的数据传输

6. **framedreadersettings.h / framedreadersettings.cpp / framedreadersettings.ui**
   - 帧读取器的设置界面
   - 配置帧格式、校验选项

7. **demoreader.h / demoreader.cpp**
   - 演示模式数据生成器
   - 生成正弦波测试数据
   - 用于测试和演示

8. **demoreadersettings.h / demoreadersettings.cpp / demoreadersettings.ui**
   - 演示读取器的设置界面
   - 配置波形参数

---

### 1.3 数据流和通道 (Stream & Channels)

#### stream.h / stream.cpp
**作用**: 核心波形存储类
- 实现`Sink`接口
- 管理多个`StreamChannel`
- 同步多通道数据
- 支持暂停、清除、缩放操作

**关键功能**:
- `setNumChannels()`: 动态改变通道数
- `setNumSamples()`: 设置缓冲区大小
- `feedIn()`: 接收数据
- `saveSettings()` / `loadSettings()`: 配置持久化

#### streamchannel.h / streamchannel.cpp
**作用**: 单个数据通道
- 包含Y数据缓冲区（可选X缓冲区）
- 通道可见性控制
- 通道名称、颜色管理

#### channelinfomodel.h / channelinfomodel.cpp
**作用**: 通道信息模型
- 实现`QAbstractTableModel`
- 管理通道元数据（名称、颜色、增益、偏移）
- 为UI提供Model/View接口

---

### 1.4 缓冲区系统 (Buffer System)

#### framebuffer.h
**作用**: 帧缓冲区抽象接口
- 定义`FrameBuffer`基类
- 定义`ResizableBuffer`（可调整大小）
- 定义`WFrameBuffer`（可写入）
- 定义`XFrameBuffer`（X轴缓冲区）

**类层次**:
```
FrameBuffer
├── ResizableBuffer
│   ├── WFrameBuffer
│   └── XFrameBuffer
```

#### ringbuffer.h / ringbuffer.cpp
**作用**: 环形缓冲区实现
- 继承`WFrameBuffer`
- 高效的FIFO数据存储
- 避免数据拷贝
- 缓存最大最小值

#### indexbuffer.h / indexbuffer.cpp
**作用**: 索引缓冲区
- 继承`XFrameBuffer`
- 用于X轴索引

#### linindexbuffer.h / linindexbuffer.cpp
**作用**: 线性索引缓冲区
- 继承`XFrameBuffer`
- 提供线性递增的X值

#### readonlybuffer.h / readonlybuffer.cpp
**作用**: 只读缓冲区
- 用于快照等场景
- 不可修改的数据视图

#### framebufferseries.h / framebufferseries.cpp
**作用**: Qwt绘图数据系列
- 继承`QwtSeriesData`
- 将`FrameBuffer`适配到Qwt
- 桥接缓冲区和绘图库

---

## 📁 模块二：绘图和可视化 (Plotting & Visualization)

### 2.1 绘图核心

#### plot.h / plot.cpp
**作用**: 主绘图类
- 继承`QwtPlot`
- 管理单个绘图窗口
- 支持缩放、网格、图例
- 暗色/亮色主题

**关键功能**:
- `showGrid()`, `showLegend()`: 显示控制
- `setYAxis()`, `setXAxis()`: 轴设置
- `darkBackground()`: 主题切换
- `flashSnapshotOverlay()`: 快照动画

#### plotmanager.h / plotmanager.cpp
**作用**: 绘图管理器
- 管理多个`Plot`对象
- 单图/多图切换
- 同步多个绘图的缩放和设置
- 导出SVG

**关键功能**:
- `setMulti()`: 切换单图/多图模式
- `addCurve()`: 添加曲线
- `syncScales()`: 同步Y轴宽度
- `exportSvg()`: 导出SVG

#### plotmenu.h / plotmenu.cpp
**作用**: 绘图菜单
- 提供绘图相关的菜单项
- 网格、图例、缩放等选项

#### plotcontrolpanel.h / plotcontrolpanel.cpp / plotcontrolpanel.ui
**作用**: 绘图控制面板
- UI面板，控制绘图显示
- Y轴范围、自动缩放
- 样本数量、绘图宽度
- 多图显示切换

---

### 2.2 交互工具 (Interaction Tools)

#### zoomer.h / zoomer.cpp
**作用**: 基础缩放工具
- 鼠标拖动缩放
- 右键恢复
- 缩放历史

#### scrollzoomer.h / scrollzoomer.cpp
**作用**: 滚动缩放工具
- 支持滚动条的缩放
- 水平滚动支持

#### scalezoomer.h / scalezoomer.cpp
**作用**: 刻度缩放工具
- 在刻度上点击缩放
- 精确的轴控制

#### scalepicker.h / scalepicker.cpp
**作用**: 刻度选择器
- 在刻度上显示值
- 鼠标交互

#### scrollbar.h / scrollbar.cpp
**作用**: 自定义滚动条
- 用于绘图的水平滚动

#### plotsnapshotoverlay.h / plotsnapshotoverlay.cpp
**作用**: 快照覆盖层
- 快照时的闪光动画
- 视觉反馈

---

### 2.3 特殊绘图 (Special Plots)

#### barplot.h / barplot.cpp
**作用**: 柱状图
- 实时柱状图显示
- 显示最新值

#### barchart.h / barchart.cpp
**作用**: 柱状图表
- 继承`QwtPlotBarChart`
- 柱状图数据管理

#### barscaledraw.h / barscaledraw.cpp
**作用**: 柱状图刻度绘制
- 自定义柱状图的刻度显示

---

## 📁 模块三：用户界面 (User Interface)

### 3.1 主窗口和入口

#### main.cpp
**作用**: 程序入口点
- 初始化QApplication
- 安装消息处理器
- 创建MainWindow
- 启动事件循环

**关键功能**:
- 自定义消息处理器（日志）
- 设置应用图标主题（Windows）
- 安装工具提示过滤器

#### mainwindow.h / mainwindow.cpp / mainwindow.ui
**作用**: 主窗口类
- 应用程序主界面
- 集成所有面板和控件
- 串口连接管理
- 菜单栏、工具栏

**管理的组件**:
- `PortControl`: 串口控制
- `DataFormatPanel`: 数据格式选择
- `PlotControlPanel`: 绘图控制
- `CommandPanel`: 命令发送
- `RecordPanel`: 数据记录
- `PlotManager`: 绘图管理
- `Stream`: 数据流
- `SnapshotManager`: 快照管理

---

### 3.2 控制面板 (Control Panels)

#### portcontrol.h / portcontrol.cpp / portcontrol.ui
**作用**: 串口控制面板
- 串口选择
- 波特率设置
- 打开/关闭连接
- 连接状态显示

#### portlist.h / portlist.cpp
**作用**: 串口列表管理
- 扫描可用串口
- 填充下拉列表
- 自动刷新

#### dataformatpanel.h / dataformatpanel.cpp / dataformatpanel.ui
**作用**: 数据格式面板
- 选择数据读取格式
- 容纳各个Reader的设置界面
- 切换Reader类型

#### commandpanel.h / commandpanel.cpp / commandpanel.ui
**作用**: 命令面板
- 管理多个命令
- 发送命令到串口
- ASCII或二进制命令

#### recordpanel.h / recordpanel.cpp / recordpanel.ui
**作用**: 记录面板
- 开始/停止数据记录
- 文件路径选择
- CSV格式选项

---

### 3.3 自定义控件 (Custom Widgets)

#### commandwidget.h / commandwidget.cpp / commandwidget.ui
**作用**: 单个命令控件
- 命令名称和内容
- 发送按钮
- ASCII/二进制切换

#### commandedit.h / commandedit.cpp
**作用**: 命令编辑器
- 支持转义字符
- 十六进制输入
- 语法高亮

#### numberformatbox.h / numberformatbox.cpp / numberformatbox.ui
**作用**: 数字格式选择框
- 选择数值类型：(u)int8/16/32, float
- 在Reader设置中使用

#### numberformat.h / numberformat.cpp
**作用**: 数字格式工具
- 数值类型转换
- 字节数计算

#### endiannessbox.h / endiannessbox.cpp / endiannessbox.ui
**作用**: 字节序选择框
- 大端/小端选择
- 在Reader设置中使用

#### ledwidget.h / ledwidget.cpp
**作用**: LED指示灯控件
- 可视化状态指示
- 颜色切换

#### sneakylineedit.h / sneakylineedit.cpp
**作用**: 特殊单行编辑器
- 特定行为的QLineEdit
- 用于特殊输入场景

#### hidabletabwidget.h / hidabletabwidget.cpp
**作用**: 可隐藏标签页控件
- 可以隐藏/显示标签栏
- 单标签时自动隐藏

#### bpslabel.h / bpslabel.cpp
**作用**: 数据速率标签
- 显示bytes per second
- 实时更新

---

### 3.4 视图和对话框 (Views & Dialogs)

#### datatextview.h / datatextview.cpp / datatextview.ui
**作用**: 数据文本视图
- 以文本形式显示数据
- 调试和监控

#### snapshotview.h / snapshotview.cpp / snapshotview.ui
**作用**: 快照视图
- 显示快照列表
- 查看和管理快照
- 导出快照

#### updatecheckdialog.h / updatecheckdialog.cpp / updatecheckdialog.ui
**作用**: 更新检查对话框
- 显示更新信息
- 版本比较

#### about_dialog.ui
**作用**: 关于对话框UI
- 显示应用信息
- 版权、版本

---

## 📁 模块四：功能模块 (Feature Modules)

### 4.1 快照功能 (Snapshot)

#### snapshot.h / snapshot.cpp
**作用**: 快照类
- 捕获当前波形数据
- 存储快照数据
- 实现`Source`接口

#### snapshotmanager.h / snapshotmanager.cpp
**作用**: 快照管理器
- 管理多个快照
- 创建、删除快照
- 快照导出为CSV

---

### 4.2 数据记录 (Data Recording)

#### datarecorder.h / datarecorder.cpp
**作用**: 数据记录器
- 实现`Sink`接口
- 将数据写入CSV文件
- 支持时间戳
- 可配置分隔符和精度

**功能**:
- `startRecording()`: 开始记录
- `stopRecording()`: 停止记录
- `addData()`: 添加数据
- 支持实时写入

---

### 4.3 更新检查 (Update Check)

#### updatechecker.h / updatechecker.cpp
**作用**: 更新检查器
- 检查新版本
- 网络请求
- 版本比较

#### versionnumber.h / versionnumber.cpp
**作用**: 版本号处理
- 解析版本字符串
- 版本比较

---

### 4.4 其他工具 (Utilities)

#### samplecounter.h / samplecounter.cpp
**作用**: 样本计数器
- 统计接收的样本数
- 计算采样率（SPS）
- 实时显示

#### tooltipfilter.h / tooltipfilter.cpp
**作用**: 工具提示过滤器
- 事件过滤器
- 自定义工具提示行为

---

## 📁 模块五：配置和定义 (Configuration)

#### defines.h
**作用**: 全局定义
- 常量定义
- 宏定义

#### setting_defines.h
**作用**: 设置相关定义
- QSettings的键定义
- 配置项常量

#### version.h
**作用**: 版本信息
- 编译时版本定义
- 来自CMake的宏

---

## 📊 文件分类统计

### 按模块统计

| 模块 | 头文件 | 实现文件 | UI文件 | 总计 |
|------|--------|---------|--------|------|
| 数据流核心 | 16 | 15 | 0 | 31 |
| 读取器 | 8 | 8 | 4 | 20 |
| 绘图可视化 | 12 | 11 | 1 | 24 |
| 用户界面 | 13 | 12 | 8 | 33 |
| 功能模块 | 8 | 7 | 3 | 18 |
| 配置定义 | 3 | 0 | 0 | 3 |
| 主程序 | 0 | 1 | 1 | 2 |
| **总计** | **60** | **54** | **17** | **131** |

### 按文件类型统计

| 类型 | 数量 |
|------|------|
| .h (头文件) | 62 |
| .cpp (实现文件) | 59 |
| .ui (界面文件) | 17 |
| **总计** | **138** |

---

## 🔗 关键依赖关系

### 核心数据流
```
Source ← AbstractReader ← BinaryStreamReader
                        ← AsciiReader
                        ← FramedReader
                        ← DemoReader

Sink ← Stream ← StreamChannel
     ← DataRecorder
```

### UI层次
```
MainWindow
├── PortControl
├── DataFormatPanel
│   └── [Reader]Settings
├── PlotControlPanel
├── CommandPanel
├── RecordPanel
└── PlotManager
    └── Plot (Qwt)
```

### 缓冲系统
```
FrameBuffer
├── ResizableBuffer
│   ├── WFrameBuffer
│   │   └── RingBuffer
│   └── XFrameBuffer
│       ├── IndexBuffer
│       └── LinIndexBuffer
└── ReadOnlyBuffer
```

---

## 📝 代码风格观察

1. **命名约定**:
   - 类名: PascalCase (例: `MainWindow`)
   - 文件名: 小写驼峰 (例: `mainwindow.cpp`)
   - 私有成员: 下划线前缀 (例: `_device`)

2. **文件组织**:
   - 每个类通常有配对的 .h 和 .cpp
   - UI类额外有 .ui 文件
   - 头文件使用 `#ifndef` 保护

3. **Qt特性使用**:
   - 信号槽机制
   - Model/View架构
   - UI文件（Qt Designer）
   - 资源系统

4. **设计模式**:
   - 工厂模式（Reader创建）
   - 观察者模式（Source-Sink）
   - Model-View-Controller

---

## 🎯 总结

SerialPlot的源代码组织清晰、模块化良好：

1. **核心分离**: 数据流、UI、绘图分离明确
2. **可扩展性**: 易于添加新Reader类型
3. **Qt集成**: 充分利用Qt框架特性
4. **测试支持**: 有独立的测试目录
5. **文档化**: 代码注释清晰

整体架构遵循SOLID原则，代码质量较高，适合作为Qt应用开发的参考项目。
