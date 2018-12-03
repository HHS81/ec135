# --------------------------------
#
# driver class for FND masterlist messages
#
# this is the generic part of the masterlist
# drivers containing the masterlist class
# --------------------------------

var sliceout = func (a,b) {
   if (size(a) == 1) return [];
   if (b+1 > size(a)) return a;
   if (b+1 == size(a)) return a[0:-2];
   if (b == 0) return a[1:];
   return a[0:b-1, b+1:];
   }

# defines colors

white=[1, 0, 0];
green=[2, 0, 0];
red=[3, 0, 0];
amber=[4, 0, 0];

# masterlist class

var masterlist = {
    new: func(path) {
		var m = { parents: [masterlist] };
		m.prio = 0;
		m.list = [];
		m.items= [];
		m.path = path;
		return m;
	},
	
    warning : func (f, c, txt1, txt2) {
      me.register(f, c, txt1, txt2, 300);},
      
    caution : func (f, c, txt1, txt2) {
      me.register(f, c, txt1, txt2, 200);},
      
    advisory: func (f, c, txt1, txt2) {
      me.register(f, c, txt1, txt2, 100);},

    info: func (f, c, txt1, txt2) {
      me.register(f, c, txt1, txt2, 0);},

    register: func (f, c, txt1, txt2, type) {
            if (me.prio < 100) {
                  append(me.items, [f, c, txt1, txt2, me.prio+type]);
                  me.prio +=1;
                } else {
                  print("masterlist error");
                }
        },
 
    sort: func() {
        # sort by priority
        me.list = sort(me.list,
        func (a,b) {if (a[3] > b[3]) return -1; else return 1;} );
        },	
	
    update: func {
       # test all conditions registered 
       # in items
      foreach (var item; me.items) {
        if (call(item[0])) {
           me.show(item[1:4]);
        } else {
           me.hide(item[1:2]);
        }
      }
      me.sort();
      me.refresh();
    },
    
    refresh: func {
       # copy the internal representation of
       # the masterlist to the property tree
       k=0;
       foreach(var txt; me.list) {
          rgb = me.col(txt[3]);   
          foreach(var i; [0,1,2]) {
             setprop(me.path ~ "[" ~ k ~ "]/msg[" ~ i ~ "]", txt[i]);
             setprop(me.path ~ "[" ~ k ~ "]/rgb[" ~ i ~ "]", rgb[i]);
          }
          k+=1;
       }
       if (k<7) me.clearlist(k);
    },
      
    show: func(item) {
       k = 0;
       #search if message alread active in list:       
       foreach(var txt; me.list) {
          if (txt[2] == item[1]) {
              # insert ENG1/ENG2 in col. 0 or 1
              if (item[0] != 2) me.list[k][item[0]] = item[2];
              return;
          }
          k+=1;
       }
       
       #message not in list append new line to list:
       theline = ["","","",""];
       theline[item[0]] = item[2];
       theline[2]       = item[1];
       theline[3]       = item[3];
       
       append(me.list, theline);
      },

    ontop: func (theline) {
      newlist = [];
      append(newlist, theline);
      foreach (var x; me.list) append(newlist, x);
      me.list = newlist;
      },
    
    hide: func(item) { 
       #search if message is active in list:
       k=0;
       foreach(var txt; me.list) {
           if (txt[2] == item[1]) {
              if (txt[0] != "" and txt[1] != "") {
                 me.list[k][item[0]] = "";
              } else if (txt[item[0]] != "") {
                 # remove list entry
                 me.list = sliceout(me.list, k);
              }
              return;
          }
          k+=1;
       }
    },
	
    clearlist: func(k) {
        #max. 7 messages in masterlist
        while (k<7) {
          foreach (var i; [0,1,2]) setprop(me.path ~ "[" ~ k ~ "]/msg[" ~ i ~ "]", "");
          k+=1;
          }
    },
    
    col: func(c) {if (c<100) return green; else if (c<200) return white; else if (c<300) return amber else return red;}
    
};
