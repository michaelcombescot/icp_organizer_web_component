import './modules/todo/todo_page';

class App {
  constructor() {
    this.#render();
  }

  #render() {
    document.getElementById('root')!.innerHTML = `
        <style>
            #root {
                padding: 1em;
                font-size: 1rem;
            }
        </style>
        
        <todo-page id="todo-page"></todo-page>

        <component-modal id="modal"></component-modal>
    `
  }
}

export default App;