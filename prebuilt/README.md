# 预编译覆盖类

本目录包含使用 Java 17 编译的修改类：

- `progsmod/plugin/ProgSMod.class`
- `progsmod/plugin/ProgSMod$ReflectionEnabledClassLoader.class`
- `progsmod/data/campaign/LunaSModButton.class`
- `progsmod/data/campaign/LunaSModButton$1.class`
- `progsmod/data/campaign/rulecmd/ui/plugins/ShipSelector.class`

这些类由仓库内的修改源码编译而来，可通过 `scripts/apply-to-original-jar.ps1` 覆盖到本地持有的 2025 原版 JAR 中。

覆盖类不包含完整原模组资产，但其中仍包含原模组包名、接口调用和修改后的实现。使用和分发时请遵守 `NOTICE.md` 中的交流用途声明。
