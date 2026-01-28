# OAT开源审查工具

## 简介

OAT（OSS Audit Tool）是从OpenHarmony社区引入的自动化开源审视工具，用于帮助开发人员基于自定义的规则自动扫描开源仓代码，识别不符合预定规则的代码并输出扫描报告。
工具详细的特性说明及使用方法请参考：<https://gitcode.com/openharmony-sig/tools_oat/blob/master/README_zh.md>

当前CodeArts check中已经集成了OAT检查的能力，用户在提交代码时门禁会自动做license检查和二进制检查。

## 开源仓规则配置

工具仓的resources/OAT-Default.xml中的定义了默认规则，如果默认规则不满足业务要求，需要在被扫描的开源仓根目录放置一个命名为 "OAT.xml"的文件作为开源仓规则，文件模版请参考：<https://gitcode.com/cann/infrastructure/blob/main/docs/SC/OAT/OAT.xml>

### license 检查配置

#### 步骤一：新增license

licensematcher name：此处定义一个名称，后续配置中需要用到

licensetext name：此处填写开源仓定义的license内容

说明：当需要支持多个license时，则在此处配置多个记录

```xml
<licensematcher name &zwnj**="cann License" desc="If the scanning result is InvalidLicense, you can define matching rules here. Note that quotation marks must be escaped.">
    <licensetext name="
        Copyright (c) 2025 Huawei Technologies Co., Ltd.
        This program is free software, you can redistribute it and/or modify it under the terms and conditions of 
        CANN Open Software License Agreement Version 2.0 (the &quot;License&quot;).
        Please refer to the License for details. You may not use this file except in compliance with the License.
        THIS SOFTWARE IS PROVIDED ON AN &quot;AS IS&quot; BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
        INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
        See LICENSE in the root of the software repository for the full text of the License." 
    desc=""/>
</licensematcher>
```

#### 步骤二：配置license策略

policyitem type：此处填写"license"

name：此处需要配置为与步骤一种的"licensematcher name"一样

path：此条license策略适用的范围

filefilter：屏蔽策略，配置屏蔽策略时需要用到

```xml
<policylist>
    <policy name="projectPolicy" desc="">
        <!--policyitem type="compatibility" name="GPL-2.0+" path="abc/.*" desc="Process that runs independently, invoked by the X process."/-->
        <policyitem type="license" name="cann License" path=".*" filefilter ="licenseFileNamePolicyFilter" desc=""/>
        <policyitem type="license" name="cann License - 2026" path=".*" filefilter ="licenseFileNamePolicyFilter" desc=""/>
    </policy>
</policylist>
```

#### 步骤三：配置屏蔽策略

filefilter name：屏蔽策略，与步骤二中的"filefilter"保持一致

filteritem type：过滤类型，支持filename、filepath两种过滤类型。

name：定义过滤条件，对于filename类型，此处定义文件名通配符，支持以"|"分隔，对于filepath类型，此处定义路径通配符。

过滤器配置如下所示：

```xml
<filefilter name="licenseFileNamePolicyFilter" desc="Filters for LICENSE file policies">
    <!--filteritem type="filename" name="*.uvwxyz" desc="Describe the reason for filtering scan results"/-->
    <!--filteritem type="filepath" name="abcdefg/.*.uvwxyz" desc="Describe the reason for filtering scan results"/-->
    <!--filteritem type="filepath" name="projectroot/[a-zA-Z0-9]{20,}.sh" desc="Temp files"/-->
</filefilter>
```
