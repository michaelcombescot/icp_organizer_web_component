import './modules/todo/todo_list';
import './modules/todo/todo_form';
import './components/modal';

class App {
  constructor() {
    this.#render();
  }

  #render() {
    document.getElementById('root')!.innerHTML = `
        <button popovertarget="modal-new-task">New task</button>
        <component-modal popover-id="modal-new-task">
            <todo-form popover-id="modal-new-task"></todo-form>
        </component-modal>

        <todo-list id="todo-list-priority"></todo-list>
        
    `
  }
}

export default App;


// <todo-list id="todo-list-date"></todo-list>