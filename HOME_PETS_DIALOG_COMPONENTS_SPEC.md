# HomePets 通用弹出层与下拉组件使用规则

## 适用范围

- 需要覆盖当前页面、让用户确认、选择或填写少量信息时，使用 `HomePetsDialog` 或 `showHomePetsDialog`。
- 需要单选列表时，使用 `HomePetsSelectField`。
- 弹出层内的主/次操作按钮，使用 `HomePetsButton`。
- 新增业务弹窗不得直接使用 `AlertDialog`、`SimpleDialog`、`DropdownButtonFormField`、`FilledButton` 或 `TextButton` 作为最终视觉层。

## 弹出层

- 文件：`app/lib/widgets/homepets_dialog.dart`
- 默认入口：`showHomePetsDialog<T>(...)`
- 需要弹窗内部自己管理复杂状态时，可以直接在 `showAppModalDialog` 里返回业务 `StatefulWidget`，业务组件根节点仍必须是 `HomePetsDialog`。
- 标题使用中文短句，最多一行；内容区不放说明型长文。
- 操作区按“取消/次要”在左，“确认/主要”在右排列。
- 弹窗宽度和高度优先使用默认 layout；只有内容明显不适配时再传自定义 `AppModalLayout`。

## 下拉选择框

- 文件：`app/lib/widgets/homepets_select_field.dart`
- 使用 `HomePetsSelectOption<T>` 提供 `value` 和中文 `label`。
- 业务侧负责维护 `value` 状态，并在 `onChanged` 中更新。
- 选项 label 必须可截断，不能依赖超长文本撑开弹窗。
- 下拉只用于单选；多选、分组或带搜索的选择器应另建同风格组件。

## 按钮

- 文件：`app/lib/widgets/homepets_button.dart`
- 主要操作使用 `HomePetsButtonVariant.primary`。
- 取消、返回、稍后等次要操作使用 `HomePetsButtonVariant.secondary`。
- 按钮文案使用中文动词短语，例如“确认完成”“取消”“保存修改”。
- 弹窗内按钮必须设置稳定宽度，避免文案变化导致操作区跳动。
- 禁用状态通过 `onPressed: null` 表达。

## 风格约束

- 用户可见文字使用中文。
- 颜色保持暖米色、浅棕、深棕和柔和橙色体系。
- 不在业务弹窗里引入新的 Material 默认外观。
- 不新增第三方依赖。
- 新增弹窗需求优先复用这三个组件，再考虑新增同风格扩展组件。
