import './modules/todo/todo_list.ts';

class App {
  constructor() {
    this.#render();
  }

  #render() {
    document.getElementById('root')!.innerHTML = `

      <todo-list></todo-list>
    `
  }
}

export default App;
