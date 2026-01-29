## 一、基础设施支撑矩阵

**支撑范围说明**：在参与开源贡献过程中，有基础设施相关需求及问题，可根据以下矩阵联系对应的支撑人咨询处理：

- 代码仓库贡献流水线部署
- CLA（贡献者许可协议）签署
- 社区机器人（如 CANN-robot）使用异常
- 流水线启动异常、任务排队等问题
- 社区邮件列表
- 社区会议
- 漏洞管理服务（cve-manager）
- CANN数字化协作平台
- 静态检查

| 支撑项 | 服务地址 | 使用指导 | GITCODE账号 | 邮箱 |  
| ------------- | ---------- | ------------------------------------------------------------------------------------- | ---------- | ---------------------- |
| 新建流水线 | NA | [使用指导](https://gitcode.com/cann/community/blob/master/contributor/repository/ci-guide.md) | [@tanghaoran7](https://gitcode.com/tanghaoran7) | <tanghaoran7@huawei.com> |
| CLA 签署 | [跳转](https://clasign.osinfra.cn/sign/68cbd4a3dbabc050b436cdd4) | [使用指导](./cla/cla使用指南.md) | [@yajie_caroline](https://gitcode.com/yajie_caroline) | <chenyajie6@huawei.com> |
| CANN-robot | NA | [使用指导](./robot/robot使用指南.md) | [@Coopermassaki](https://gitcode.com/Coopermassaki) | <fuyong29@h-partners.com> |
| 社区邮件列表 | [跳转](https://mailweb.cann.osinfra.cn/) | [使用指导](./mail-list/邮件列表使用指南.md) | [@weixin_43493709](https://gitcode.com/weixin_43493709) | <zhuchao50@h-partners.com> |
| 社区会议服务 | [跳转](https://meeting.osinfra.cn/cann) | [使用指导](./meeting/CANN社区会议指南.md) | [@ZeesangPie](https://gitcode.com/ZeesangPie) | <chenglang11@huawei.com> |
| 漏洞管理服务 | NA | [使用指导](./cve-manager/manual.md) | [@yangwei999](https://gitcode.com/yangwei999) | <yangwei266@h-partners.com> |
| CANN数字化协作平台 | [跳转](https://digital.hicann.cn//) | [使用指导](./CANN-Digital-Platform/网站介绍.md) | [@fanxiaotian6](https://gitcode.com/fanxiaotian6) | <fanxiaotian6@huawei.com> |
| 静态检查 | NA | [使用指导](./SC/CodeArts-Check/CodeArts-Check插件使用指南.md) | [@weixin_39767879](https://gitcode.com/weixin_39767879) | <zhuzheng3@huawei.com> |

---

## 二、组件仓库 CIE 支撑矩阵git

**支撑范围说明**：您在参与开源贡献过程中，若遇到流水线、代码合入等问题，优先联系对应组件仓库的 CIE（持续集成工程师） 支撑处理：

- 编译构建异常
- UT（单元测试）执行异常
- 冒烟测试任务执行异常
- 静态检查结果屏蔽审核
- 代码合入异常

| 模块 | 仓名 | GITCODE账号 | 邮箱 |
| ------ | ------ | --------- | ------ |
| 算子 | cann/opbase | [@songkai111](https://gitcode.com/songkai111) | <songkai16@huawei.com> |
| | cann/ops-cv | [@liu-wei](https://gitcode.com/liu-wei) | <lovline.liuwei@huawei.com> |
| | cann/ops-math | [@songkai111](https://gitcode.com/songkai111) | <songkai16@huawei.com> |
| | cann/ops-nn | [@yangyang016](https://gitcode.com/yangyang016) | <yangyang306@hisilicon.com> |
| | cann/ops-transformer | [@CoderChenxi](https://gitcode.com/CoderChenxi) | <chenxi116@huawei.com> |
| | cann/atvoss | [@Sunee](https://gitcode.com/Sunee) | <sunyi35@huawei.com> |
| AscendC | cann/asc-devkit | [@DragonBornHD84](https://gitcode.com/DragonBornHD84)<br>[@chenyiyuan](https://gitcode.com/chenyiyuan) | <huangduo4@hisilicon.com><br><chenyiyuan5@huawei.com> |
| | cann/asc-tools | [@DragonBornHD84](https://gitcode.com/DragonBornHD84)<br>[@chenyiyuan](https://gitcode.com/chenyiyuan) | <huangduo4@hisilicon.com><br><chenyiyuan5@huawei.com> |
| | cann/pyasc | [@kong0808](https://gitcode.com/kong0808) | <kongqiongzhuo@huawei.com> |
| | cann/atvc | [@wulinyu](https://gitcode.com/wulinyu) | <wulinyu4@huawei.com> |
| 基础图框架 | cann/graph-autofusion | [@jikai-tyler](https://gitcode.com/jikai-tyler) | <jikai5@huawei.com> |
| | cann/hixl | [@jikai-tyler](https://gitcode.com/jikai-tyler) | <jikai5@huawei.com> |
| 驱动 | cann/driver | [@ad_cx](https://gitcode.com/ad_cx) | <fengchengxiang@huawei.com> |
| 集合通信 | cann/hccl | [@jiyuanhao](https://gitcode.com/jiyuanhao) | <jiyuanhao1@huawei.com> |
| | cann/hcomm | [@jiyuanhao](https://gitcode.com/jiyuanhao) | <jiyuanhao1@huawei.com> |
| 运行时 | cann/runtime | [@duanpengliang](https://gitcode.com/duanpengliang) | <duanpengliang@huawei.com> |
| 基础工具 | cann/amct | [@RQL7](https://gitcode.com/RQL7) | <renqilin2@h-partners.com> |
| | cann/oam-tools | [@sinat_31531339](https://gitcode.com/sinat_31531339) | <yuanyue23@huawei.com> |
| 算法 | cann/cann-recipes-embodied-intelligence | [@rous_zhang](https://gitcode.com/rous_zhang) | <zhangxinfang5@hisilicon.com> |
| | cann/cann-recipes-harmony-infer | [@rui-zhang](https://gitcode.com/rui-zhang) | <zhangrui329@hisilicon.com> |
| | cann/cann-recipes-infer | [@rui-zhang](https://gitcode.com/rui-zhang) | <zhangrui329@hisilicon.com> |
| | cann/cann-recipes-preview | [@rui-zhang](https://gitcode.com/rui-zhang) | <zhangrui329@hisilicon.com> |
| | cann/cann-recipes-spatial-intelligence | [@lushirui22](https://gitcode.com/lushirui22) | <lushirui@hisilicon.com> |
| | cann/cann-recipes-train | [@zhanghz1](https://gitcode.com/zhanghz1) | <zhanghaozhuo1@hisilicon.com> |
| PTO | cann/pto-tile-lib | [@y30038433](https://gitcode.com/y30038433) | <yefei37@h-partners.com> |
| | cann/pto-isa | [@y30038433](https://gitcode.com/y30038433) | <yefei37@h-partners.com> |
| | cann/pypto | [@DCGDDD](https://gitcode.com/DCGDDD) | <yangxu14@huawei.com> |
| 扩展 | cann/ascend-transformer-boost | [@overfitting_zh](https://gitcode.com/overfitting_zh) | zhanghan72@huawei.com |
| | cann/shmem | [@overfitting_zh](https://gitcode.com/overfitting_zh) | zhanghan72@huawei.com |
| | cann/catlass | [@overfitting_zh](https://gitcode.com/overfitting_zh) | zhanghan72@huawei.com |
| | cann/ascend-boost-comm | [@overfitting_zh](https://gitcode.com/overfitting_zh) | zhanghan72@huawei.com |
| | cann/ascend-transformer-boost | [@overfitting_zh](https://gitcode.com/overfitting_zh) | zhanghan72@huawei.com |