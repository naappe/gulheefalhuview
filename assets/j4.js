const cart=document.getElementById('cart'),cartBody=document.getElementById('cartBody'),cartCount=document.getElementById('cartCount'),mobileCartCount=document.getElementById('mobileCartCount'),cartTotal=document.getElementById('cartTotal');
const sendOrderButton=document.getElementById('sendOrder');
const cartActions=document.createElement('div');
cartActions.className='cart-actions';
sendOrderButton.before(cartActions);
cartActions.append(sendOrderButton);
const clearOrderButton=document.createElement('button');
clearOrderButton.type='button';
clearOrderButton.id='clearOrder';
clearOrderButton.className='btn ghost clear-order';
clearOrderButton.textContent='Clear order';
cartActions.append(clearOrderButton);
let cartLastFocus=null;cart.inert=true;
function itemByName(name){for(const c of cats){const item=MENU[c].find(x=>x.n===name);if(item)return item}return null}
function saveCart(){try{localStorage.setItem(CART_KEY,JSON.stringify(cartData))}catch{}}
function isValidQty(q){return Number.isInteger(q)&&q>0&&q<=99}
function validCartEntries(){return Object.entries(cartData).filter(([name,q])=>isValidQty(q)&&itemByName(name))}
function cartStats(){let count=0,total=0;validCartEntries().forEach(([name,q])=>{const x=itemByName(name);count+=q;total+=x.p*q});return{count,total}}
function renderCart(){Object.keys(cartData).forEach(name=>{if(!itemByName(name)||!isValidQty(cartData[name]))delete cartData[name]});const entries=validCartEntries();const stats=cartStats();cartCount.textContent=stats.count;mobileCartCount.textContent=stats.count+' '+(stats.count===1?'item':'items');cartTotal.textContent='MVR '+stats.total;clearOrderButton.disabled=!entries.length;cartBody.innerHTML=entries.length?entries.map(([name,q])=>{const x=itemByName(name);return `<div class="cart-row"><div><h4>${name}</h4><small>MVR ${x.p} each</small><div class="qty"><button type="button" data-dec="${name}" aria-label="Decrease ${name}">−</button><strong>${q}</strong><button type="button" data-inc="${name}" aria-label="Increase ${name}">+</button></div></div><strong>MVR ${x.p*q}</strong></div>`}).join(''):`<div class="cart-empty">Your order is empty.<br>Add dishes from the menu.</div>`;saveCart()}
function setCart(open){const wasOpen=cart.classList.contains('open');if(open){setDrawer(false);cartLastFocus=document.activeElement;cart.inert=false}else cart.inert=true;cart.classList.toggle('open',open);cart.setAttribute('aria-hidden',String(!open));document.body.classList.toggle('lock',open);overlay.classList.toggle('show',open);if(open)requestAnimationFrame(()=>document.getElementById('cartClose').focus());else if(wasOpen&&cartLastFocus&&document.body.contains(cartLastFocus))cartLastFocus.focus()}
document.querySelectorAll('.js-open-cart').forEach(b=>b.addEventListener('click',()=>setCart(true)));document.getElementById('cartClose').onclick=()=>setCart(false);grid.addEventListener('click',e=>{const b=e.target.closest('[data-add]');if(!b)return;const current=isValidQty(cartData[b.dataset.add])?cartData[b.dataset.add]:0;cartData[b.dataset.add]=Math.min(current+1,99);renderCart();toast(`${b.dataset.add} added`)});cartBody.addEventListener('click',e=>{const inc=e.target.closest('[data-inc]'),dec=e.target.closest('[data-dec]');if(inc){const current=isValidQty(cartData[inc.dataset.inc])?cartData[inc.dataset.inc]:0;cartData[inc.dataset.inc]=Math.min(current+1,99)}if(dec){const current=isValidQty(cartData[dec.dataset.dec])?cartData[dec.dataset.dec]:1;cartData[dec.dataset.dec]=current-1;if(cartData[dec.dataset.dec]<=0)delete cartData[dec.dataset.dec]}if(inc||dec)renderCart()});
clearOrderButton.addEventListener('click',()=>{cartData={};renderCart();toast('Order cleared')});
function orderMessage(){const entries=validCartEntries();if(!entries.length)return '';const lines=entries.map(([name,q])=>{const x=itemByName(name);return `• ${q} × ${name} — MVR ${x.p*q}`});return `Hello Gulheefalhu View,\n\nI would like to place an order:\n\n${lines.join('\n')}\n\nEstimated total: MVR ${cartStats().total}\n\nPlease confirm availability, final total and collection/delivery details.`}
async function copyText(text){try{await navigator.clipboard.writeText(text);return true}catch{return false}}