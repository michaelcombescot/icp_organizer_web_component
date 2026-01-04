import { Language } from "./i18n";

export const french: Language = {
    headerTitle: "Organizer",
    headerHome: "Accueil",
    headerTodoLists: "Listes de tâches",
    headerSignIn: "Connexion",
    headerSignUp: "Inscription",
    headerLogOut: "Déconnexion",

    // homepage
    todoCreateNewButton: "Nouvelle tâche",
    todoListCreateButton: "Nouvelle liste",
    groupSelectorLabel: "Sélectionnez un groupe...",
    groupCreateButton: "Nouveau groupe",
    listSelectorLabel: "Sélectionnez une liste...",

    // todoForm
    todoFormTitleNew: "Nouvelle tâche",
    todoFormTitleEdit: "Modifier la tâche",
    todoFormFieldResume: "Résumé",
    todoFormFieldResumePlaceholder: "Résumé de la tâche",
    todoFormFieldDescription: "Description",
    todoFormFieldDescriptionPlaceholder: "Description de la tâche",
    todoFormFieldScheduledDate: "Date limite de réalisation",
    todoFormFieldPriority: "Priorité",
    todoFormPriorities: {
        "low": "Faible",
        "medium": "Moyenne",
        "high": "Elevée"
    },
    todoFormFieldStatus: "Statut",
    todoFormStatuses: {
        "pending": "En cours",
        "done": "Terminee"
    },
    todoFormFieldList: "Liste",
    todoFormInputSubmit: "Enregistrer",

    // list form
    todoListFormTitleNew: "Nouvelle liste",
    todoListFormTitleEdit: "Modifier la liste",
    todoListFormFieldName: "Nom",
    todoListFormFieldNamePlaceholder: "Nom de la liste",
    todoListFormFieldColor: "Couleur",
    todoListFormInputSubmit: "Enregistrer",

    // list card
    todoListCardConfirmDelete: "Voulez-vous vraiment supprimer cette liste ? Cette action est irreversible et supprimera toutes les tâches associées.",
    todoListCardSeeAll: "Voir toutes les tâches",
}