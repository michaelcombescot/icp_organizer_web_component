import { french } from "./french";
import { TodoPriority } from "../modules/todo/models/todo";

export const i18n = french

export interface Language {
    headerTitle: string
    headerHome: string
    headerTodoLists: string
    headerSignIn: string
    headerSignUp: string
    headerLogOut: string

    // homepage
    todoCreateNewButton: string

    todoFormTitleNew: string
    todoFormTitleEdit: string
    todoFormFieldResume: string
    todoFormFieldResumePlaceholder: string
    todoFormFieldDescription: string
    todoFormFieldDescriptionPlaceholder: string
    todoFormFieldScheduledDate: string
    todoFormFieldPriority: string
    todoFormPriorities: Record<string, string>
    todoFormFieldStatus: string
    todoFormStatuses: Record<string, string>
    todoFormInputSubmit: string

    // lists
    todoListCreateButton: string

    todoListFormTitleNew: string,
    todoListFormTitleEdit: string,
    todoListFormFieldName: string,
    todoListFormFieldNamePlaceholder: string,
    todoListFormFieldColor: string,
    todoListFormInputSubmit: string,
}