# API 端点与 Token 细节

## Base 与版本

| base | 端点域 | 备注 |
|------|--------|------|
| `https://api.gitcode.com/api/v5` | PR、issue、评论、文件 | 标准 Gitea 风格 |
| `https://api.gitcode.com/api/v8` | actions（workflows/runs/jobs/download_log） | **v5 对 actions 全部 404** |

## 认证

```
Authorization: Bearer $GC_TOKEN
```

- token 从用户处获取或环境变量 `GC_TOKEN` / `SENTRY_GC_TOKEN`
- 查询类 token 即可（本技能全程 GET）

## 端点速查

### v5

```
GET /repos/{org}/{repo}/pulls/{n}                 # PR 详情（head/base/labels/merge状态）
GET /repos/{org}/{repo}/pulls/{n}/comments        # PR 评论（run 链接、/compile 重试、评审意见）
GET /repos/{org}/{repo}/pulls/{n}/files?per_page=100  # 改动文件与 patch
```

### v8

```
GET /repos/{org}/{repo}/actions/workflows                    # workflow 列表（发现 workflow_id）
GET /repos/{org}/{repo}/actions/runs?workflow_id=..&page=..&per_page=100
GET /repos/{org}/{repo}/actions/runs/{run_id}                # 详情：stages[].jobs[]（时间戳 ms）
GET /repos/{org}/{repo}/actions/runs/{run_id}/jobs           # jobs+steps 明细
GET /repos/{org}/{repo}/actions/runs/{run_id}/jobs/{job_id}/download_log  # 失败 job 日志 zip
```

## 已知坑（实测）

1. **download_log 返回 302**：Location 是 `raw.gitcode.com/...?access_token=<token>`。
   - 用 `curl -L` 跟随即可；token 会被拼进 URL，注意日志脱敏
   - 返回 `200 + 0 字节`：该 job 无归档（成功 job 永远如此；新 run 可能平台归档延迟）
   - **只有 FAILED job 有日志**；要对照成功 job 只能翻同仓库更早的失败 run 或换对照维度
2. **run 详情 vs jobs API**：run 详情的 stages[].jobs[] 已含绝大多数字段（含 message），
   但 steps 明细（编译步骤耗时）需要 jobs API。identifier 带 `_0` 的是内层真实执行 job。
3. **run_number ≠ run_id**：PR 评论链接里的 32 位 hex 是 workflow_run_id；
   `run_number` 是人类可读序号（如 #5816）。两者都用 API 换算。
4. **分页**：runs 列表 page=1..N，per_page=100；按 start_time 毫秒降序。
5. **PR head_sha 不一定是 run 的 head_sha**：run 的 head_sha 是 merge_commit（含 master 最新），
   根因关联 PR 改动时以 PR files 为准。
6. **status 字段可能带尾缀**：如 `FAILED(1)`，解析时 split("(")[0]。

## 时间戳换算

- 所有 start_time/end_time 均为 **毫秒 epoch**
- 分钟 = `(end-start)/60000`
- 本地时区展示：`datetime.fromtimestamp(ms/1000, timezone(timedelta(hours=8)))`

## workflow_id 发现

```
GET /api/v8/repos/cann/{repo}/actions/workflows
→ 找 name == "PR-pipeline_{repo}" 的 workflow_id
```

常见值（截至 2026-09）：
- ops-transformer: `ac0cf9bb4ec341d08b2346ff78548c9f`
- ops-nn: `9463dc6e843444598cf84e764681c764`
- 发现失败时逐仓库现查，勿硬编码。
