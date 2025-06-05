import { french } from "./french";

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
}