# 根因分析

## 环境

- 游戏版本：Starsector `0.98a-RC8`
- 经验内插：Progressive S-Mods `1.2.0`
- 经验内插 JAR 构建日期：2025-06-04
- 骤雨军事公司：Arma Armatura `3.3.6`
- Java：游戏自带 JRE 17

## 故障链

### 1. 原版写入完整舰船对象

Progressive S-Mods 1.2.0 在两个 UI 入口执行类似代码：

```java
dialog.getInteractionTarget().getMemory().set("$selectedShip", member);
```

`member` 是完整的 `FleetMemberAPI` 实现对象，不是舰船 ID，也不是可安全重建的普通数据。

### 2. 市场内存进入存档

交互目标的内存是持久化对象。保存游戏时，`$selectedShip` 会连同其舰船对象、舰长、模块、维修状态和 `FleetData` 引用一起被 XStream 写入 `campaign.xml`。

### 3. 骤雨组合舰扩大对象图

相关舰船为：

```text
armaa_garegga_xiv_carrier_Hull
```

它带有：

- `armaa_comboUnit`；
- `MODULE` 模块变体；
- 平台与模块上的 `progsmod_xptracker`；
- 大量玩家舰队引用。

购买或保留该舰后，玩家舰队对象图明显变复杂，改变 XStream 的遍历顺序。

### 4. 提前执行 readResolve

读取存档时，XStream 从市场内存中的 `$selectedShip` 提前展开 `FleetMember` 与 `FleetData`。此时全局玩家舰队尚未恢复。

随后：

```text
FleetMember.readResolve()
  -> 访问玩家舰队数据
  -> SectorAPI.getPlayerFleet() == null
  -> NullPointerException
```

异常导致整个存档读取失败。

## 日志证据

核心堆栈：

```text
method              : com.fs.starfarer.campaign.fleet.FleetMember.readResolve()
class               : com.fs.starfarer.campaign.fleet.FleetMember
cause-exception     : java.lang.NullPointerException
cause-message       : null
```

更详细的一次 JVM 空指针说明：

```text
Cannot invoke "CampaignFleetAPI.getFleetData()"
because the return value of "SectorAPI.getPlayerFleet()" is null
```

## 存档对照

本地对照结果如下：

| 存档 | 玩家舰队状态 | 结果 |
| --- | --- | --- |
| `save__7251742823580938767` | 激活的 `AASV Achilleus` 组合单位 | 读取失败 |
| `save__671759993573906490` | 激活的 `AASV Alcinous` 组合单位 | 同一异常失败 |
| `save__3614338536332502502` | 激活的 `AASV Alcinous` 组合单位 | 同一异常失败 |
| `save__163579570737613033` | 仅有教程/非舰队组合对象 | 成功完成加载阶段 39 |

该对照表明：问题不是“合并按钮”本身，而是购买并把这类组合对象带入玩家舰队后，原版经验内插遗留的持久化舰船引用改变了序列化顺序。

## 为什么删除 `$selectedShip` 是低风险修复

正常经验内插界面在选船后会直接把 `FleetMemberAPI` 传给：

```java
PSM_BuildInHullMod.createPanel(...)
```

因此界面功能不依赖市场内存中的 `$selectedShip`。

原代码注释也说明该键主要用于控制台命令：

```java
// Set $selectedShip, which is used by the console commands
```

删除该写入不会影响经验计算、船插内置、S-插件上限或战斗监听器。

## 为什么载入后还要清理

只删除写入代码只能阻止新键产生，无法删除可加载存档中已经存在的旧键。

补丁在 `onGameLoad` 中遍历：

- 所有星系实体；
- 超空间实体；
- 所有舰队。

并对每个对象执行：

```java
entity.getMemoryWithoutUpdate().unset("$selectedShip");
```

下一次保存后，旧键不会再进入存档。

## 为什么不能修复已经坏掉的存档

存档读取失败发生在 XStream 反序列化阶段。此时模组插件的 `onGameLoad` 尚未运行，游戏也没有可操作的 Sector 对象。

因此必须：

1. 从坏档之前的可加载备份继续；或
2. 使用存档编辑工具修复已有 `campaign.xml`。

本补丁只解决后续存档再次产生该问题的风险。
