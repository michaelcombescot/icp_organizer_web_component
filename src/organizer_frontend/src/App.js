import './modules/todo/todo_list.js';
import './components/modal.js';

class App {
  constructor() {
    this.#render();
  }

  #render() {
    document.getElementById('root').innerHTML = `
        <button popovertarget="new-task">New task</button>
        <component-modal popover-id="new-task">
            <div>CONTENT</div>
        </component-modal>

        <todo-list></todo-list>
    `
  }
}

export default App;
