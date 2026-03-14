# 上传到 Netlify 说明

## 要上传的文件夹

请上传 **整个 `website` 文件夹** 里的内容到 Netlify。

- 路径：`Puff/website/`
- 需要包含的文件：`index.html`（本文件夹内所有文件一并上传即可）

## Netlify 部署步骤

1. 登录 [Netlify](https://app.netlify.com)
2. 点击 **Add new site** → **Deploy manually**
3. 将 **`website` 文件夹** 拖拽到页面上的上传区域（或把该文件夹内所有文件拖进去）
4. 部署完成后，Netlify 会给你一个地址，例如：  
   `https://随机名称.netlify.app`  
   或你自定义的子域名：`https://puffdiary.netlify.app`

## 部署后请把地址发给我

把你的 **完整 Netlify 地址**（例如 `https://puffdiary.netlify.app`，**不要** 末尾的 `/`）发给我，我会在 App 代码里更新：

- 订阅页的「使用条款」链接 → 你的地址（首页）
- 订阅页的「隐私政策」链接 → 你的地址 + `#privacy`

这样 App 内点击链接会正确打开你部署的页面。
