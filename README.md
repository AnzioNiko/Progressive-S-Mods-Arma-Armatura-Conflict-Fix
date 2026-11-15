# 经验内插（Progressive S-Mods）骤雨冲突修复

英文仓库名：`Progressive-S-Mods-Arma-Armatura-Conflict-Fix`

本仓库提供一个针对 **Progressive S-Mods 经验内插 1.2.0（2025 原版）** 的本地兼容性补丁，用于阻止其把完整的 `FleetMember` 持久化到市场内存中，从而规避与 **骤雨军事公司（Arma Armatura）** 组合型舰船相关的存档读取崩溃。

> 本项目不是原模组作者发布的官方更新。仅用于技术交流、兼容性测试和本地问题排查，禁止商用、付费整合、商业分发或冒充官方版本。

## 问题现象

购买并保留骤雨的组合型舰船后，游戏可以保存，但重新读取存档时可能失败。日志中的关键异常为：

```text
ERROR com.fs.starfarer.campaign.save.CampaignGameManager - Failed calling method
method: com.fs.starfarer.campaign.fleet.FleetMember.readResolve()
cause-exception: java.lang.NullPointerException
```

更早的一次异常带有完整说明：

```text
Cannot invoke "CampaignFleetAPI.getFleetData()"
because the return value of "SectorAPI.getPlayerFleet()" is null
```

## 根因摘要

Progressive S-Mods 原版会把当前选择舰船的完整 `FleetMember` 写入交互目标的市场内存键 `$selectedShip`：

- `progsmod/data/campaign/rulecmd/ui/plugins/ShipSelector.java`
- `progsmod/data/campaign/LunaSModButton.java`

这个键只用于部分开发者控制台命令，正常经验内插界面并不依赖它。市场内存会随存档一起保存，因此完整舰船对象及其 `FleetData` 引用也会被写入存档。

骤雨的 `armaa_garegga_xiv_carrier_Hull` 组合型舰船带有：

- `armaa_comboUnit` 船插；
- 嵌套的 `MODULE` 模块变体；
- 经验内插的 `progsmod_xptracker`；
- 平台、模块和玩家舰队之间的多重对象引用。

这些对象组合会改变 XStream 的反序列化顺序，使某个 `FleetMember.readResolve()` 在 `CampaignEngine.getPlayerFleet()` 尚未恢复时提前执行，最终触发空指针。

完整分析、对照存档和日志证据见 [docs/root-cause.md](docs/root-cause.md)。

## 补丁内容

1. `ShipSelector.java`
   - 删除向交互目标内存写入 `$selectedShip` 的代码。
   - 保留原有舰船选择和经验内插面板创建逻辑。

2. `LunaSModButton.java`
   - 删除 LunaLib 改装界面入口对 `$selectedShip` 的持久化写入。
   - 保留原有按钮和面板逻辑。

3. `ProgSMod.java`
   - 每次存档成功载入后，遍历全部星系、超空间、实体和舰队，清理旧版本遗留的 `$selectedShip`。
   - 清理发生在 `onGameLoad(boolean)`，不会改变正常游戏数据。

补丁不会影响经验内插的核心功能，包括经验获取、内置船插、超出上限的 S-插件和部署点惩罚。受影响的只有依赖 `$selectedShip` 的开发者控制台便捷命令。

## 从 2025 原版修改

补丁基线是本地 `Progressive S-Mods.jar` 2025 年版本：

- 模组版本：`1.2.0`
- JAR 日期：`2025-06-04 08:21:28`
- JAR SHA-256：`A23E127E9F1258826449EDD11517914B1D163368F3A566C54A5BF0A15EDFCF77`
- 原始 JAR 不纳入 Git 提交，避免重新分发完整第三方模组。

基线信息也保存在 [metadata/baseline-2025.json](metadata/baseline-2025.json)。

### 方法一：直接使用预编译覆盖类

1. 准备 2025 原版 `Progressive S-Mods.jar`。
2. 执行：

```powershell
.\scripts\apply-to-original-jar.ps1 `
  -OriginalJar "D:\path\to\Progressive S-Mods.jar" `
  -OutputJar ".\dist\Progressive S-Mods.jar"
```

3. 用输出 JAR 替换模组中的：

```text
mods\D-经验内插\jars\Progressive S-Mods.jar
```

### 方法二：修改源码后自行编译

1. 将 `src/` 中的三个修改文件覆盖到原模组源码目录。
2. 设置 Starsector 目录和 LunaLib JAR 路径。
3. 执行：

```powershell
.\scripts\build.ps1 `
  -StarsectorDir "D:\Games\Starsector098" `
  -OriginalJar "D:\path\to\Progressive S-Mods.jar"
```

4. 编译结果位于 `build/classes`。
5. 执行 `apply-to-original-jar.ps1` 生成覆盖后的完整 JAR。

### 方法三：审阅并应用统一补丁

在 2025 原模组源码根目录执行：

```bash
git apply "D:\Games\Starsector098\Progressive-S-Mods-Arma-Armatura-Conflict-Fix\patches\progsmod-selected-ship-savefix.patch"
```

补丁只修改三个 Java 文件。

## 使用注意事项

1. 先完全退出游戏。
2. 备份原始 `Progressive S-Mods.jar`。
3. 加载一个当前能够正常进入的游戏存档。
4. 成功载入后，补丁会自动清理旧 `$selectedShip` 键。
5. 立即另存到新槽位，并重启游戏验证读取。
6. 若补丁仍无法解决同一问题，请保留 `starsector.log` 并检查是否还有第二个独立对象引用问题。

## 已有坏档说明

本补丁不能直接修复已经无法加载的坏档。

原因是坏档在 XStream 反序列化阶段就失败了，而 `onGameLoad` 只有在存档成功完成反序列化后才会执行。必须从购买或组合前的可加载备份继续，或使用专门的存档编辑工具处理已有坏档。

## 验证记录

已完成：

- 使用 Java 17 编译三个修改文件；
- 更新 JAR 后检查无重复条目和签名冲突；
- 字节码确认两个 UI 类不再包含写入 `$selectedShip` 的调用；
- 字节码确认 `ProgSMod` 包含载入清理逻辑；
- 使用游戏自带 JRE 17 成功加载三个修改后的类。

尚未自动执行完整的“购买舰船、保存、退出、读取”游戏内闭环测试，避免覆盖用户的当前存档。该测试需要在可丢弃的测试存档中完成。

详细命令和哈希记录见 [metadata/verification-2026-11-16.txt](metadata/verification-2026-11-16.txt)。

## 回滚

替换前请保留原 JAR。需要回滚时，用原始 2025 `Progressive S-Mods.jar` 覆盖回：

```text
mods\D-经验内插\jars\Progressive S-Mods.jar
```

## 声明

本项目仅作为技术交流和兼容性验证使用。

- 原模组及其源码版权归原作者和汉化参与者所有。
- 本仓库不对原模组主张所有权。
- 禁止将本补丁用于售卖、付费整合包、商业服务或其他商业用途。
- 不得将本补丁表述为原作者的官方更新。
- 使用前必须自行备份存档和模组文件；使用风险由使用者自行承担。
