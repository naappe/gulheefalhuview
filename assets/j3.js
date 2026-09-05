function renderTabs(){tabs.innerHTML=cats.map((c,i)=>`<button class="tab ${c===activeCat?'active':''}" role="tab" aria-selected="${c===activeCat}" tabindex="${c===activeCat?0:-1}" data-cat="${c}" id="menu-tab-${i}">${c}</button>`).join('')}
function escapeHTML(value){return String(value).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;')}
function renderMenu(){
  const q=search.value.trim().toLowerCase();
  const items=q
    ? Object.entries(MENU).flatMap(([cat,list])=>list.filter(x=>(x.n+' '+x.d).toLowerCase().includes(q)).map(x=>({...x,cat})))
    : MENU[activeCat].map(x=>({...x,cat:activeCat}));
  grid.innerHTML=items.length?items.map(x=>`<article class="menu-item"><img loading="lazy" src="${IMG(x.i)}" alt="${x.n}" width="92" height="78" onerror="menuImageFallback(this,'${x.cat.replaceAll("'","\\'")}','${x.n.replaceAll("'","\\'")}')"><div><h3>${x.n}${q?`<span class="hit-cat">${x.cat}</span>`:''}</h3><p>${x.d}</p><div class="menu-actions"><button class="add-btn" type="button" data-add="${x.n.replaceAll('"','&quot;')}">+ Add to order</button></div></div><div class="menu-price">MVR ${x.p}</div></article>`).join(''):`<div class="no-results">No dishes match “${escapeHTML(search.value)}”. Try a different word, or ask us on WhatsApp.</div>`
}
function activateCategory(cat,scroll=false){activeCat=cat;search.value='';renderTabs();renderMenu();if(scroll)document.getElementById('menu').scrollIntoView({behavior:'smooth'})}
tabs.addEventListener('click',e=>{const b=e.target.closest('[data-cat]');if(b)activateCategory(b.dataset.cat)});
tabs.addEventListener('keydown',e=>{const btns=[...tabs.querySelectorAll('[role="tab"]')];const i=btns.indexOf(document.activeElement);if(i<0)return;let next=null;if(e.key==='ArrowRight')next=(i+1)%btns.length;if(e.key==='ArrowLeft')next=(i-1+btns.length)%btns.length;if(e.key==='Home')next=0;if(e.key==='End')next=btns.length-1;if(next!==null){e.preventDefault();activateCategory(btns[next].dataset.cat);requestAnimationFrame(()=>tabs.querySelectorAll('[role="tab"]')[next].focus())}});
search.addEventListener('input',renderMenu);renderTabs();renderMenu();
document.getElementById('dessertButton').addEventListener('click',()=>activateCategory('Desserts',true));
const navLinks=[...document.querySelectorAll('.navlinks a')],header=document.getElementById('header');
const navSections=navLinks.map(a=>({a,section:document.querySelector(a.getAttribute('href'))})).filter(x=>x.section);
let scrollTicking=false;
function updateNavState(){header.classList.toggle('scrolled',scrollY>24);const y=scrollY+130;let current='home';navSections.forEach(({section})=>{if(section.offsetTop<=y)current=section.id});navSections.forEach(({a})=>a.classList.toggle('active',a.getAttribute('href')==='#'+current));scrollTicking=false}
addEventListener('scroll',()=>{if(scrollTicking)return;scrollTicking=true;requestAnimationFrame(updateNavState)},{passive:true});
updateNavState();
const menuBtn=document.getElementById('menuBtn'),drawer=document.getElementById('drawer'),overlay=document.getElementById('overlay');
let drawerLastFocus=null;drawer.inert=true;
function setDrawer(open){const wasOpen=drawer.classList.contains('open');if(open){drawerLastFocus=document.activeElement;drawer.inert=false}else drawer.inert=true;drawer.classList.toggle('open',open);overlay.classList.toggle('show',open);drawer.setAttribute('aria-hidden',String(!open));menuBtn.setAttribute('aria-expanded',String(open));document.body.classList.toggle('lock',open);menuBtn.textContent=open?'×':'☰';menuBtn.setAttribute('aria-label',open?'Close navigation':'Open navigation');if(open)requestAnimationFrame(()=>drawer.querySelector('a,button')?.focus());else if(wasOpen&&drawerLastFocus&&document.body.contains(drawerLastFocus))drawerLastFocus.focus()}
menuBtn.addEventListener('click',()=>setDrawer(!drawer.classList.contains('open')));overlay.addEventListener('click',()=>{setDrawer(false);setCart(false)});drawer.querySelectorAll('a').forEach(a=>a.addEventListener('click',()=>setDrawer(false)));
const gallery=document.getElementById('galleryGrid'),lightbox=document.getElementById('lightbox'),lbImg=document.getElementById('lbImg');let galleryIndex=0,lastFocus=null;
gallery.innerHTML=GALLERY.map((g,i)=>`<button type="button" data-gallery="${i}" aria-label="Open photo: ${g[1]}"><img loading="lazy" src="${IMG(g[0])}" alt="${g[1]}" onerror="this.onerror=null;this.src='assets/placeholder.svg'"></button>`).join('');
function setLightboxImage(i){galleryIndex=i;lbImg.alt=GALLERY[i][1];lbImg.onerror=()=>{lbImg.onerror=null;lbImg.src='assets/placeholder.svg';lbImg.alt='Restaurant photo temporarily unavailable'};lbImg.src=IMG_BIG(GALLERY[i][0])}
function openLightbox(i){lastFocus=document.activeElement;setLightboxImage(i);lightbox.classList.add('open');document.body.classList.add('lock');document.getElementById('lbClose').focus()}
function closeLightbox(){lightbox.classList.remove('open');document.body.classList.remove('lock');if(lastFocus&&document.body.contains(lastFocus))lastFocus.focus()}
function stepGallery(n){setLightboxImage((galleryIndex+n+GALLERY.length)%GALLERY.length)}
gallery.addEventListener('click',e=>{const b=e.target.closest('[data-gallery]');if(b)openLightbox(+b.dataset.gallery)});document.getElementById('lbClose').onclick=closeLightbox;document.getElementById('lbPrev').onclick=()=>stepGallery(-1);document.getElementById('lbNext').onclick=()=>stepGallery(1);lightbox.addEventListener('click',e=>{if(e.target===lightbox)closeLightbox()});
let touchStart=0;lightbox.addEventListener('touchstart',e=>touchStart=e.touches[0].clientX,{passive:true});lightbox.addEventListener('touchend',e=>{const d=e.changedTouches[0].clientX-touchStart;if(Math.abs(d)>45)stepGallery(d<0?1:-1)},{passive:true});
const CART_KEY='gv_order_v2';let cartData={};try{cartData=JSON.parse(localStorage.getItem(CART_KEY)||'{}')||{}}catch{cartData={}}