import './modules/todo/element_todo_page';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import "dayjs/locale/fr";

class App {
  constructor() {
    dayjs.locale(navigator.language || navigator.languages[0])
    dayjs.extend(relativeTime)

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