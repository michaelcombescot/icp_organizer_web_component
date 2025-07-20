import { french } from "./french";
import { TodoPriority } from "../modules/todo/models/todo";

export const i18n = french

export interface Language {
    headerTitle: string
    headerHome: string
    headerAbout: string
    headerContact: string
    headerSignIn: string
    headerSignUp: string
    headerLogOut: string

    todoCreateNewButton: string

    todoFormTitleNew: string;
    todoFormTitleEdit: string;
    todoFormFieldResume: string,
    todoFormFieldResumePlaceholder: string,
    todoFormFieldDescription: string,
    todoFormFieldDescriptionPlaceholder: string,
    todoFormFieldScheduledDate: string,
    todoFormFieldPriority: string,
    todoFormPriorities: Record<string, string>
    todoFormFieldStatus: string,
    todoFormStatuses: Record<string, string>,
    todoFormInputSubmit: string,
}