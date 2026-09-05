document.getElementById('sendOrder').addEventListener('click',async()=>{const msg=orderMessage();if(!msg){toast('Add at least one dish first.');return}if(SITE.whatsapp){window.open(`https://wa.me/${SITE.whatsapp.replace(/\D/g,'')}?text=${encodeURIComponent(msg)}`,'_blank','noopener');return}const ok=await copyText(msg);toast(ok?'Order summary copied.':'Order summary is ready, but clipboard access was blocked.')});
const rDate=document.getElementById('rDate');const localNow=new Date();localNow.setMinutes(localNow.getMinutes()-localNow.getTimezoneOffset());rDate.min=localNow.toISOString().slice(0,10);
function reservationText(f){return `Hello Gulheefalhu View,\n\nI would like to request a reservation.\n\nName: ${f.name.value}\nPhone: ${f.phone.value}\nDate: ${f.date.value}\nTime: ${f.time.value}\nGuests: ${f.guests.value}\nPreference: ${f.preference.value}\nSpecial request: ${f.note.value||'None'}\n\nPlease confirm availability.`}
document.getElementById('reserveForm').addEventListener('submit',async e=>{e.preventDefault();const f=e.currentTarget,msg=document.getElementById('formMsg');let valid=true;f.querySelectorAll('[required]').forEach(el=>{const bad=!el.value.trim();el.classList.toggle('error',bad);if(bad)valid=false});if(!valid){msg.textContent='Please complete the required fields.';return}const text=reservationText(f);msg.textContent='';if(SITE.whatsapp){window.open(`https://wa.me/${SITE.whatsapp.replace(/\D/g,'')}?text=${encodeURIComponent(text)}`,'_blank','noopener');return}const ok=await copyText(text);msg.textContent=ok?'Reservation request copied.':'Reservation request is ready, but clipboard access was blocked.'});
function polishCustomerCopy(){
  const set=(sel,text)=>{const el=document.querySelector(sel);if(el)el.textContent=text};
  set('.menu .section-copy','Fire-kissed pizzas, tandoor plates, naan, seafood, desserts and drinks — all made fresh in a kitchen built around the flame.');
  set('.menu-note','All prices in Maldivian Rufiyaa (MVR). Availability may change. Please speak with our team about allergies and dietary requirements.');
  set('.service .section-copy','Dine with us, collect your favourites, or have them delivered — choose the way that suits your day.');
  set('.service-card.delivery p','Build your order from the menu and send it to us on WhatsApp for confirmation.');
  set('.gallery .section-copy','Evenings here are built on warm light, generous plates and the energy of the fire kitchen.');
  set('.reserve .section-copy','Choose your date, time and table preference, then send your reservation request to us on WhatsApp.');
  set('.review-empty h3','Guest reviews coming soon.');
  set('.review-empty p','We’re looking forward to sharing verified feedback from our first diners.');
  set('.contact .section-copy','Gulheefalhu, Maldives. Call or WhatsApp us for directions, reservations and orders.');
  const orderBtn=document.getElementById('sendOrder');if(orderBtn)orderBtn.textContent='Send Order on WhatsApp';
  const reserveBtn=document.querySelector('#reserveForm button[type="submit"]');if(reserveBtn)reserveBtn.textContent='Request Reservation on WhatsApp';
  const mapBtn=document.getElementById('mapLink');if(mapBtn)mapBtn.textContent='Get Directions';
  const contactBtn=document.getElementById('contactButton');if(contactBtn)contactBtn.textContent='WhatsApp Us';
  const contactImg=document.querySelector('.contact-photo img');if(contactImg){contactImg.src='https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1200&q=82';contactImg.alt='Warm restaurant entrance and dining atmosphere';}
}
function applySiteConfig(){
  const mapLink=document.getElementById('mapLink'),phoneNode=document.getElementById('phoneText'),emailNode=document.getElementById('emailText'),hoursNode=document.getElementById('hoursText');
  mapLink.href=SITE.map;
  phoneNode.innerHTML=SITE.phone?`<a href="tel:${SITE.phone.replace(/\s/g,'')}">${SITE.phone}</a>`:'To be confirmed';
  emailNode.innerHTML=SITE.email?`<a href="mailto:${SITE.email}">${SITE.email}</a>`:'To be confirmed';
  hoursNode.textContent=SITE.hours||'Hours available on request';
  const booking=document.getElementById('bookingState'),cartStatus=document.getElementById('cartStatus');
  if(SITE.whatsapp){booking.textContent='Reservation requests open directly in WhatsApp for quick confirmation.';cartStatus.textContent='Send your order on WhatsApp and we’ll confirm availability and the final total.'}
  const contactButton=document.getElementById('contactButton');contactButton.addEventListener('click',()=>{if(SITE.whatsapp){window.open(`https://wa.me/${SITE.whatsapp.replace(/\D/g,'')}?text=${encodeURIComponent('Hello Gulheefalhu View, I have an enquiry.')}`,'_blank','noopener')}else if(SITE.phone){location.href='tel:'+SITE.phone.replace(/\s/g,'')}else if(SITE.email){location.href='mailto:'+SITE.email}else toast('Restaurant contact details are currently unavailable.')});
  const schemaEl=document.querySelector('script[type="application/ld+json"]');if(schemaEl){try{const schema=JSON.parse(schemaEl.textContent);schema.telephone=SITE.phone;schema.email=SITE.email;schema.openingHours='Mo-Su 11:00-23:00';schemaEl.textContent=JSON.stringify(schema)}catch{}}
}
function toast(text){const t=document.getElementById('toast');t.textContent=text;t.classList.add('show');clearTimeout(window.__toast);window.__toast=setTimeout(()=>t.classList.remove('show'),3000)}
const io='IntersectionObserver'in window?new IntersectionObserver(entries=>entries.forEach(e=>{if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target)}}),{threshold:.1}):null;document.querySelectorAll('.reveal').forEach(el=>io?io.observe(el):el.classList.add('in'));
function trapTab(e,root){const focusable=[...root.querySelectorAll('a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])')].filter(el=>!el.inert&&el.offsetParent!==null);if(!focusable.length)return;const first=focusable[0],last=focusable[focusable.length-1];if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus()}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus()}}
document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(lightbox.classList.contains('open'))closeLightbox();else if(cart.classList.contains('open'))setCart(false);else if(drawer.classList.contains('open'))setDrawer(false)}if(lightbox.classList.contains('open')){if(e.key==='ArrowLeft')stepGallery(-1);if(e.key==='ArrowRight')stepGallery(1);if(e.key==='Tab')trapTab(e,lightbox)}else if(cart.classList.contains('open')&&e.key==='Tab')trapTab(e,cart);else if(drawer.classList.contains('open')&&e.key==='Tab')trapTab(e,drawer)});
polishCustomerCopy();applySiteConfig();renderCart();