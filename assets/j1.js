const SITE={
  phone:"+960 7635654",
  whatsapp:"9607635654",
  email:"naappe@gmail.com",
  hours:"Daily · 11:00 AM – 11:00 PM",
  reservationStart:"11:00",
  reservationLast:"22:30",
  map:"https://www.google.com/maps/search/?api=1&query=Gulheefalhu%2C%20Maldives",
  instagram:"",
  facebook:"",
  tiktok:""
};

/* Image references:
   - Unsplash: keep the existing photo id, e.g. "1565299624946-b28f40a0ae38"
   - Pexels: prefix the numeric photo id with "px:", e.g. "px:5639973"
   Width/quality are requested per component so menu thumbnails do not download
   the same large files used by signature cards or the lightbox.
*/
const imageWidth=w=>Math.max(160,Math.min(2000,Number(w)||720));
const imageQuality=q=>Math.max(55,Math.min(90,Number(q)||78));
const IMG=(ref,w=720,q=78)=>{
  const width=imageWidth(w),quality=imageQuality(q),value=String(ref);
  if(value.startsWith('px:')){
    const id=value.slice(3);
    return `https://images.pexels.com/photos/${id}/pexels-photo-${id}.jpeg?auto=compress&cs=tinysrgb&w=${width}&q=${quality}`;
  }
  return `https://images.unsplash.com/photo-${value}?auto=format&fit=crop&w=${width}&q=${quality}`;
};
const IMG_BIG=(ref,w=1600,q=84)=>IMG(ref,w,q);

const IMAGE_FALLBACKS={
  "Tandoori Pizzas":["1565299624946-b28f40a0ae38","1594007654729-407eedc4be65","1571407970349-bc81e7e96d47"],
  "Fire Kitchen":["1555939594-58d7cb561ad1","1603360946369-dc9bb6258143","1540420773420-3366772f4999"],
  "Fire Handhelds":["px:29306505","px:6416559","px:34320705","px:7936651"],
  "Desserts":["1606313564200-e75d5e30476c","1571877227200-a0d98ea607e9","1533134242443-d4fd215305ad"],
  "Drinks":["1551538827-9c037cb4f32a","1536935338788-846bb9981813","1523677011781-c91d1bbe2f9e"]
};
function menuFallbackRef(cat,name=''){
  const list=IMAGE_FALLBACKS[cat]||IMAGE_FALLBACKS['Tandoori Pizzas'];
  let hash=0;for(const ch of name)hash=(hash*31+ch.charCodeAt(0))>>>0;
  return list[hash%list.length];
}
function menuImageFallback(img,cat,name){
  if(img.dataset.fallbackTried==='1'){
    img.onerror=null;
    img.src='assets/placeholder.svg';
    return;
  }
  img.dataset.fallbackTried='1';
  const width=img.closest('.menu-item')?240:760;
  img.src=IMG(menuFallbackRef(cat,name),width,74);
}

const MENU={
  "Tandoori Pizzas":[
    {n:"Tandoori Chicken Pizza",p:145,d:"Smoky tandoori chicken, mozzarella, red onion, capsicum and house tandoor sauce.",i:"1565299624946-b28f40a0ae38"},
    {n:"Chicken Tikka Pizza",p:150,d:"Chicken tikka, mozzarella, roasted capsicum, onion and mint-yoghurt finish.",i:"1594007654729-407eedc4be65"},
    {n:"Fajita Fire Pizza",p:145,d:"Grilled chicken, peppers, onion, jalapeño and mozzarella.",i:"1571407970349-bc81e7e96d47",tags:["spicy"]},
    {n:"Keema Fire Pizza",p:160,d:"Spiced minced meat, mozzarella, red onion, green chilli and herbs.",i:"px:30120985",tags:["spicy"]},
    {n:"Seafood Fire Pizza",p:165,d:"Prawns, squid, roasted tomato, chilli, garlic and mozzarella.",i:"px:5639973",tags:["spicy"]},
    {n:"Four Cheese Tandoor Pizza",p:150,d:"A rich four-cheese blend finished with herbs.",i:"px:17800186"},
    {n:"Veggie Fire Pizza",p:135,d:"Roasted vegetables, mushrooms, olives, onion and mozzarella.",i:"px:11975887",tags:["veg"]}
  ],
  "Fire Kitchen":[
    {n:"Clay-Pot Chicken Biryani",p:130,d:"Fragrant rice and marinated chicken layered and finished in a clay pot.",i:"1589302168068-964664d93dc0"},
    {n:"Fire-Roasted Prawns",p:165,d:"Prawns roasted with garlic, chilli, lemon and herbs.",i:"1625943553852-781c6dd46faa"},
    {n:"Seekh Kebab Fire Platter",p:180,d:"Spiced kebabs, charred over high heat and served with fresh accompaniments.",i:"1555939594-58d7cb561ad1"},
    {n:"Tandoori Chicken Platter",p:150,d:"Marinated chicken cooked for smoke, char and tenderness.",i:"1603360946369-dc9bb6258143"},
    {n:"Tandoor Maldivian Fish",p:165,d:"Fish marinated with warming spice and finished over intense heat.",i:"1467003909585-2f8a72700288"},
    {n:"Fire-Roasted Vegetable Platter",p:95,d:"Seasonal vegetables roasted and finished with herbs.",i:"1540420773420-3366772f4999",tags:["veg"]}
  ],
  "Fire Handhelds":[
    {n:"Loaded Tandoor Naan",p:65,d:"Fresh naan loaded with cheese, herbs and tandoor butter.",i:"1579871494447-9811cf80d66c",tags:["veg"]},
    {n:"Chicken Naan Pocket",p:90,d:"Warm naan stuffed with tandoori chicken, salad and mint yoghurt.",i:"1601050690597-df0568f70950"},
    {n:"Mas Huni Stuffed Naan",p:75,d:"A Maldivian-inspired tuna, coconut and onion filling inside fresh naan.",i:"1509440159596-0249088772ff"},
    {n:"Garlic Cheese Naan",p:45,d:"Fresh naan brushed with garlic butter and melted cheese.",i:"1568254183919-78a4f43a2877",tags:["veg"]},
    {n:"Tandoori Chicken Wrap",p:85,d:"Tandoori chicken, crisp vegetables and mint yoghurt in a soft wrap.",i:"px:29306507"},
    {n:"Tandoor Chicken Shawarma",p:80,d:"Fire-charred tandoori chicken, garlic sauce, pickles, onion and lettuce wrapped in fresh flatbread.",i:"px:29306505",tags:["new"]},
    {n:"Fire Chicken Shawarma Loaded",p:95,d:"A larger shawarma packed with tandoori chicken, cheese, fire chilli sauce and garlic sauce.",i:"px:18177338",tags:["new","spicy"]},
    {n:"Tandoor Chicken Burger",p:100,d:"Tandoori chicken, cheese, charred onion, lettuce and mint-garlic sauce in a toasted bun.",i:"px:34320705",tags:["new"]},
    {n:"Tandoor Potato Wedges",p:40,d:"Crispy seasoned potato wedges finished with fire spice and served with garlic sauce.",i:"px:7936651",tags:["new","veg"]}
  ],
  "Desserts":[
    {n:"Molten Chocolate Clay Pot",p:75,d:"Warm chocolate cake with a soft molten centre.",i:"1606313564200-e75d5e30476c"},
    {n:"Tiramisu",p:75,d:"Coffee-soaked layers with mascarpone and cocoa.",i:"1571877227200-a0d98ea607e9"},
    {n:"New York Cheesecake",p:65,d:"Rich baked cheesecake with a smooth creamy centre.",i:"1533134242443-d4fd215305ad"},
    {n:"Saffron Milk Cake",p:75,d:"Soft sponge soaked with fragrant saffron milk.",i:"1578985545062-69928b1d9587"},
    {n:"Fire-Roasted Pineapple",p:60,d:"Pineapple caramelised with heat and served warm.",i:"px:32844957"},
    {n:"Chocolate Banana Sweet Naan",p:65,d:"Sweet naan with banana and chocolate.",i:"1612201142855-7873bc1661b4"},
    {n:"Tandoor Brownie Skillet",p:70,d:"Warm chocolate brownie served in a small skillet.",i:"1607920591413-4ec007e70023"},
    {n:"Burnt Honey Banana",p:55,d:"Warm banana finished with caramelised honey.",i:"1528207776546-365bb710ee93"}
  ],
  "Drinks":[
    {n:"Passion Mojito",p:45,d:"Passion fruit, mint, lime and soda over ice.",i:"1551538827-9c037cb4f32a"},
    {n:"Peach Mojito",p:45,d:"Peach, mint and lime, gently muddled over ice.",i:"1536935338788-846bb9981813"},
    {n:"Blue Lagoon",p:50,d:"A bright zero-alcohol citrus cooler.",i:"px:36901264"},
    {n:"Mint Lemon",p:35,d:"Fresh mint and lemon served chilled.",i:"1523677011781-c91d1bbe2f9e"},
    {n:"Saffron Sunset Cooler",p:50,d:"A saffron-led signature cooler.",i:"px:29002944"},
    {n:"Coconut Lime Cooler",p:45,d:"Coconut, lime and mint served cold.",i:"px:30920615"},
    {n:"Iced Latte",p:45,d:"Espresso with chilled milk over ice.",i:"1461023058943-07fcbe16d735"},
    {n:"Karak Chai",p:25,d:"Slow-brewed spiced milk tea.",i:"px:36326292"}
  ]
};