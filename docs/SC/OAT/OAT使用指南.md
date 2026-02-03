# OAT开源审查工具

## 目的

本文档旨在为开发者提供明确的指引，当社区门禁系统中**code_check**扫描任务检测到由[OAT（OSS Audit Tool）](https://gitcode.com/openharmony-sig/tools_oat)发出的开源合规告警时，应如何理解、分析并采取正确的操作步骤进行处理。

---

## 范围

本指导适用于所有参与CANN社区的贡献者，项目适用范围包含：[CANN](https://gitcode.com/cann)下代码仓。

---

## OAT问题确认

开源仓代码扫描时候会根据[OAT默认规则](https://gitcode.com/openharmony-sig/tools_oat#%E9%BB%98%E8%AE%A4%E8%A7%84%E5%88%99%E9%85%8D%E7%BD%AE)进行分析，不满足则会在OAT扫描报告中呈现出如下的问题。

具体处理流程如下：

![image](./images/image.png)

---

具体分析操作如下：

### 问题一：为什么测试文件/配置文件也被报出许可证问题？

#### 告警示例：

![image](./images/example_1.png)
![image](./images/example_2.png)

#### 问题原因：

OAT 工具默认会对仓库中所有文件进行扫描。但某些文件（如 `tests/` 目录下的单元测试脚本、`pyproject.toml` 等构建配置文件）本身不涉及核心功能或不具备版权敏感性，无需纳入许可证合规检查。

这类文件若被扫描，容易误报为“无许可证头”或“未知许可证”，增加无效告警负担。

#### 正确做法：

将这些**非源码类或无需审计的文件/目录**加入屏蔽列表，在项目根目录的 `OAT.xml` 中配置过滤规则。

##### 操作示例：

1. **屏蔽整个测试目录**

```xml
<filefilter name="defaultFilter" desc="Files not to check">
    <filteritem type="filepath" name="tests/.*" desc="Test files do not require license check"/>
</filefilter>
```

2. **屏蔽特定配置文件（如 toml 文件）**

```xml
<filefilter name="defaultFilter" desc="Files not to check">
    <filteritem type="filename" name="pyproject.toml" desc="Configuration file, no license required"/>
</filefilter>
```

> ⚠️ 注意：
>
> * 使用 `filepath` 可匹配路径正则；
> * 使用 `filename` 匹配具体文件名；
> * 修改后需提交至主干并同步到 CI 环境才生效。

---

### 问题二：告警说用了某个许可证（如 CANN-2.0），但确认是可以用的，怎么办？

#### 告警示例：

![image](./images/example_3.png)

#### 问题原因：

OAT 扫描发现代码中声明使用了某个许可证（例如 `CANN-2.0`），但由于该许可证未在当前项目的白名单中注册，系统无法识别其合法性，因此标记为风险项。
这并不意味着许可证不能用，而是工具“不认识它”。

#### 正确做法：

明确告知 OAT：这个许可证是允许使用的。你需要在项目根目录的  `OAT.xml` 中将其添加到许可策略中。

##### 操作示例：

```xml
<policylist>
    <policy name="projectPolicy" desc="Project allowed licenses">
        <policyitem type="license" name="CANN-2.0" path=".*" desc="Approved CANN license"/>
    </policy>
</policylist>
```

> ✅ 要求：
> 
> * `name` 字段必须与扫描报告中的许可证名称​**完全一致**​；
> * `path=".*"` 表示适用于全仓文件，也可按需限定路径。<br>
>   ✅ 完成后，下次扫描将不再提示该许可证为非法

---

### 问题三：为什么提示“NoLicenseHeader”？

#### 告警示例：

![image](./images/example_4.png)

#### 问题原因：

“NoLicenseHeader” 表示该文件缺少标准的许可证声明头部注释。常见于以下两类情况：

| 类型                                           | 是否需要补头      |
| -----------------------------------------------|-------------------|
| 自研代码文件（`.c`,`.h`,`.py`等）              | ✅ 建议补充       |
| 上游引入的第三方开源文件                       | ❌ 不应修改原内容 |

如果你的文件属于第二种（比如从上游社区 copy 的代码），原始就没有许可证头，此时报错是合理的误报。

#### 正确做法：

根据文件性质选择处理方式：

##### ✅ 场景 A：这是自研代码 → 补充许可证头

在文件顶部添加如下标准声明（以 CANN-2.0 为例）：

```c++
/*
* This program is free software, you can redistribute it and/or modify it under the terms and conditions of
* CANN Open Software License Agreement Version 2.0 (the "License").
* Please refer to the License for details. You may not use this file except in compliance with the License.
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
* INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
* See LICENSE in the root of the software repository for the full text of the License.
  */
```

##### ✅ 场景 B：这是上游引入文件 → 屏蔽检查

保持原始内容不变，在项目根目录的 `OAT.xml` 中通过 `defaultPolicyFilter` 忽略该文件的许可证头检查。

```xml
<filefilter name="defaultPolicyFilter" desc="Files exempt from license header checks">
    <filteritem type="filepath" name="/example/atb_aclnn/memory/memory_utils.h" desc="Third-party upstream file without license header"/>
    <filteritem type="filename" name="memorypool.cpp" desc="Imported code, no header modification allowed"/>
</filefilter>
```

> 📝 原因说明建议写清楚，便于后续审计追溯。

---

### 问题四：出现“InvalidLicense”告警，工具识别不出许可证？

#### 告警示例：

![image](./images/example_5.png)

#### 问题原因：

OAT 无法匹配到已知许可证库中的条目，可能因为：

* 许可证文本格式有微小差异（空格、换行、标点等）；
* 使用了新定义或定制化的许可证（如 CANN-2.0 尚未收录）；
* 文本编码或大小写导致特征不匹配。
  此时会报 `InvalidLicense`，表示“识别失败”，而非“禁止使用”。

#### 正确做法：

先人工确认许可证内容是否合法 → 再决定如何让工具能识别它。

##### 步骤 1：人工分析 + 法务确认

* 查看告警文件中的许可证声明原文；
* 提交法务团队确认该许可证是否可用于本项目；
* 若不可用 → 需替换或移除相关代码；
* 若可用 → 继续下一步。

##### 步骤 2：选择一种方式让 OAT 能识别该许可证

###### 方式 A：向 OAT 工具提交许可证定义（推荐长期使用）

> 👉 提交流程：[OAT Gitcode 仓库](https://gitcode.com/openharmony-sig/tools_oat)

要求：

* 提取许可证正文，转为小写，去除所有符号和空格；
* 填入 JSON 格式的 license definition。

###### 示例：

```json
{
"licenseHeaderText": "thisprogramisfreesoftwareyoucanredistributeitandormodifyitunderthetermsandconditionsofcannopensoftwarelicenseagreementversion20thelicensepleaserefertothelicensefordetailsyoumaynotusethisfileexceptincompliancewiththelicensethissoftwareisprovidedonanasisbasiswithoutwarrantiesofanykindeitherexpressorimpliedincludingbutnottononinfringementmerchantabilityorfitnessforaparticularpurposeseelicenseintherootofthesoftwarerepositoryforthefulltextofthelicense",
"licenseHeaderTextLength": 450,
"licenseId": "CANN-2.0",
"licenseName": "CANN Open Software License Agreement Version 2.0",
"licenseText": "...same as above...",
"urls": []
}
```

> ✅ 优点：一次提交，多仓受益<br>
> ❗ 缺点：需等待工具版本发布才能生效

###### 方式 B：在当前仓配置本地匹配规则（快速生效）

直接在项目根目录的 `OAT.xml` 中添加 `<licensematcher>` 规则，​**原样复制许可证头/文本内容**​（**注意**：转义引号，**Copyright版权信息**不要写入）。

```xml
<licensematcherlist>
    <licensematcher name="CANN-2.0" desc="Custom license matcher for InvalidLicense fix">
        <licensetext name="
             * This program is free software, you can redistribute it and/or modify it under the terms and conditions of
             * CANN Open Software License Agreement Version 2.0 (the &quot;License&quot;).
             * Please refer to the License for details. You may not use this file except in compliance with the License.
             * THIS SOFTWARE IS PROVIDED ON AN &quot;AS IS&quot; BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
             * INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
             * See LICENSE in the root of the software repository for the full text of the License.
         " desc="Match CANN-2.0 license header"/>
    </licensematcher>
</licensematcherlist>
```

> ✅ 优点：提交即生效，适合紧急修复<br>
> ❗ 缺点：每个仓库都要重复配置，维护成本高<br><br>
> 💡 建议：优先走方式 A 提交公共库，方式 B 作为过渡方案
