import { french } from "./french";

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
    todoListCreateButton: string

    // todo form
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
    todoFormFieldList: string
    todoFormInputSubmit: string

    // list form
    todoListFormTitleNew: string,
    todoListFormTitleEdit: string,
    todoListFormFieldName: string,
    todoListFormFieldNamePlaceholder: string,
    todoListFormFieldColor: string,
    todoListFormInputSubmit: string,

    // list card
    todoListCardConfirmDelete: string
    todoListCardSeeAll: string
}