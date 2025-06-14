import './modules/todo/component_todo_page';
import './components/modal';
import { html, css, LitElement } from 'lit';
import { customElement } from 'lit/decorators.js';

@customElement('main-app')
class App extends LitElement {
    static styles = css`
        #main-app {
            padding: 1em;
            font-size: 1rem;
        }
    `

    protected render() { 
        return html`       
            <div id="main-app">     
                <component-todo-page></component-todo-page>

                <component-modal></component-modal>
            </div>
        `
    }
}