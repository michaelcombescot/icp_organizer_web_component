import { french } from "./french";
import { Priority } from "../modules/todo/components/component_todo";

export const i18n = french

export interface Language {
    todoCreateNewButton: string

    todoFormTitleNew: string;
    todoFormTitleEdit: string;
    todoFormFieldResume: string,
    todoFormFieldDescription: string,
    todoFormFieldScheduledDate: string,
    todoFormFieldPriority: string,
    todoFormFieldStatus: string,
    todoFormInputSubmit: string,
    todoFormPriority: Record<Priority, string>
}