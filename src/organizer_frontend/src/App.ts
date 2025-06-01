import './modules/todo/todo_page';

class App {
  constructor() {
    this.#render();
  }

  #render() {
    document.getElementById('root')!.innerHTML = `
        <style>
            #root {
                font-size: 1rem;
            }
        </style>
        
        <todo-page id="todo-page"></todo-page>
    `
  }
}

export default App;