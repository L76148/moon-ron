# moon-ron 项目申报书

## 基本信息

- 项目名称：Moon RON：Rusty Object Notation 的 MoonBit 解析与序列化库
- 参赛者：L76148
- 联系方式：2237501538@qq.com
- GitHub 仓库链接：https://github.com/L76148/moon-ron
- 项目方向：MoonBit 数据格式 / 序列化基础库
- 是否为移植项目：是

## 项目简介

Moon RON 将 Rusty Object Notation（RON）的解析、序列化和类型化转换能力移植到 MoonBit 生态，为配置读取、测试夹具、游戏与仿真数据以及 Rust/MoonBit 跨语言数据交换提供可复用基础库。

Mooncakes 现有 JSON、TOML、YAML、KDL、HCL 等包不能完整表达 RON 的 struct、tuple struct、enum variant、Option、range、byte literal 和扩展属性语义。项目采用手写递归下降解析器，将通用值树、格式化、源码诊断与类型化转换分层，避免把 Rust 特有语义耦合进核心实现。

## 核心功能范围

- 提供 `RonValue` 通用值树，支持标量、字符串、原始字符串、字节串、Option、序列、元组、映射、struct、tuple struct、enum、range 和注释；
- 支持官方扩展属性，包括 `unwrap_newtypes`、`implicit_some`、`unwrap_variant_newtypes` 和 `explicit_struct_names`；
- 提供紧凑序列化 `to_string` 和确定性多行格式化 `to_string_pretty`；
- 提供 `FromRon`、`ToRon` 类型化转换，覆盖常用基础类型、数组、固定数组、Map、Result、元组、自定义 struct 和 enum；
- 提供带行列号、源码片段和插入符的 `render_error` 与 `render_decode_error`；
- 提供 `check`、`format`、`compact` 三命令 CLI；
- 提供可运行示例、兼容性 corpus、核心路径测试、GitHub Actions CI 和 mooncakes.io 发布。

## 预期验收产物

- 可直接通过 `moon add L76148/moon-ron@0.1.1` 使用的 MoonBit 库；
- 可运行命令：`moon run cmd/ron -- check|format|compact <file>`；
- 49 个测试覆盖解析、序列化、格式化、扩展、range、类型化转换、诊断和 CLI；
- README、API 文档、迁移说明、第三方许可证说明和完整示例；
- Apache-2.0 根许可证；
- 已发布至 mooncakes.io：`L76148/moon-ron@0.1.1`。

## 移植或参考说明

- 原项目名称：RON（Rust `ron` crate）
- 原项目链接：https://github.com/ron-rs/ron
- 原项目许可证：MIT OR Apache-2.0
- 本项目许可证：Apache-2.0

与参考实现相比，本项目使用 MoonBit 原生包结构、类型系统和测试方式重新组织代码；优先实现可在 MoonBit 中独立运行的数据模型、解析、序列化、格式化和类型化转换；不实现 Rust 编译器集成、第三方 crate 自动绑定、二进制 RON 扩展或任意脚本执行。
