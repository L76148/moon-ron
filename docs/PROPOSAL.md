# 项目申报书：MoonBit RON 解析与序列化库

1. **项目名称**：`moon-ron`（MoonBit RON parsing and serialization）
2. **GitHub 仓库**：https://github.com/L76148/moon-ron
3. **项目定位**：为 MoonBit 补齐 Rusty Object Notation（RON）的原生解析、序列化和类型化转换能力，服务配置、测试数据和跨语言交换场景。
4. **生态缺口**：截至 2026-09-28，`moon search ron` 未发现 RON 实现；现有 JSON、TOML、YAML、KDL、HCL 包均不能解析 RON 的 struct、tuple struct、enum variant、Option 和 byte literal 语义。
5. **参考项目**：Rust `ron` crate（https://github.com/ron-rs/ron），MIT/Apache-2.0；本项目独立实现，不复制上游代码，并保留第三方说明。
6. **预期场景一**：MoonBit 服务读取由 Rust 服务生成的 RON 配置，同时保留注释和类型形态。
7. **预期场景二**：游戏或仿真项目使用 RON 编写场景、关卡、实体与枚举配置。
8. **预期场景三**：开发工具读取、检查和规范化测试夹具、快照及结构化样例。
9. **首个增量**：解析 RON 文本为通用 `RonValue` 树，支持标量、字符串与原始字符串、字节串、序列、元组、映射、struct、tuple struct、enum、Option、注释、嵌套深度限制和源码位置错误。
10. **核心 API**：`parse(source, max_nesting_depth?) -> RonValue`、`valid(source) -> Bool`，以及 `RonValue`、`RonNumber`、`RonError`、`RonPosition`。
11. **后续增量**：规范序列化、类型化 `FromRon`/`ToRon` 转换、格式化器、扩展配置、CLI 与更多一致性测试，每项独立提交和验收。
12. **技术路线**：手写递归下降解析器；词法与语法层负责源位置和错误恢复边界；通用值树与类型化转换分层，避免把 Rust 特有语义耦合进核心解析器。
13. **工程质量**：使用 `moon check --deny-warn`、`moon test --deny-warn`、`moon fmt --check` 和 GitHub Actions；每个功能提供可运行示例、核心路径测试和接口变更记录。
14. **开源规范**：Apache-2.0 根许可证；README 说明目标、安装、用法和示例；后续发布至 mooncakes.io。
15. **明确不做**：本阶段不实现 Rust 编译器集成、第三方 crate 自动绑定、网络协议、二进制 RON 扩展或任意脚本执行。
16. **提交要求**：开发期内按可验证功能积累不少于 10 个真实 commits，不使用空提交、重复提交或无意义拆分。
