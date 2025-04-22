// insert styles into the page with javascript
document.head.insertAdjacentHTML('beforeend', `
              <style>
                p {
                  page-break-after: always;
                }
              </style>
            `);
document.body.insertAdjacentHTML('beforeend', `
              <p>7</p>
              <p>8</p>
            `);