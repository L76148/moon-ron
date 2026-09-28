# 项目申报书：MoonBit RON 解析与序列化库

1. **项目名称**：`moon-ron`（MoonBit RON parsing and serialization）
2. **GitHub 仓库**：https://github.com/L76148/moon-ron
3. **项目定位**：为 MoonBit 补齐 Rusty Object Notation（RON）的原生解析、序列化和类型化转换能力，服务配置、测试数据和跨语言交换场景。
4. **生态缺口**：截至 2026-09-29，Mooncakes 上不存在可替代的 RON 实现；现有 JSON、TOML、YAML、KDL、HCL 包均不能完整解析 RON 的 struct、tuple struct、enum variant、Option、range 和 byte literal 语义。
5. **参考项目**：Rust `ron` crate（https://github.com/ron-rs/ron），MIT/Apache-2.0；本项目独立实现，不复制上游代码，并保留第三方说明。
6. **预期场景一**：MoonBit 服务读取由 Rust 服务生成的 RON 配置，同时保留注释和类型形态。
7. **预期场景二**：游戏或仿真项目使用 RON 编写场景、关卡、实体与枚举配置。
8. **预期场景三**：开发工具读取、检查和规范化测试夹具、快照及结构化样例。
9. **交付范围**：纯 MoonBit 实现通用值树、递归下降解析器、紧凑与多行序列化、源码诊断、range、全部官方扩展属性、`FromRon`/`ToRon` 类型化转换、CLI 和兼容性语料。
10. **核心 API**：`parse`、`valid`、`to_string`、`to_string_pretty`、`decode`、`encode`、`render_error`、`render_decode_error`，以及 `RonValue`、`RonOptions`、`RonExtensions` 等类型。
11. **工程质量**：49 个测试覆盖解析、序列化、格式化、扩展、range、类型化转换和诊断；GitHub Actions 通过 `moon check --deny-warn`、`moon test --deny-warn` 和 `moon fmt --check`。
12. **技术路线**：手写递归下降解析器；词法与语法层负责源位置和错误恢复边界；通用值树与类型化转换分层，避免把 Rust 特有语义耦合进核心解析器。
13. **工程质量**：使用 `moon check --deny-warn`、`moon test --deny-warn`、`moon fmt --check` 和 GitHub Actions；每个功能提供可运行示例、核心路径测试和接口变更记录。
14. **开源规范**：使用 Apache-2.0 根许可证；README 完整说明目标、安装、用法和示例；已发布 `L76148/moon-ron@0.1.1` 至 mooncakes.io。
15. **明确不做**：本阶段不实现 Rust 编译器集成、第三方 crate 自动绑定、网络协议、二进制 RON 扩展或任意脚本执行。
16. **提交要求**：开发期内按可验证功能积累不少于 10 个真实 commits，不使用空提交、重复提交或无意义拆分。
