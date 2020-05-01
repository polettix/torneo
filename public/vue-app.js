function _page_url_for_tid (tid) {
   var myurl = new URL(window.location.href);
   myurl.searchParams.set('tid', tid);
   return myurl;
}

function _data_url_base() {
   var myurl = new URL(window.location.href);
   return myurl.pathname.replace(/\/[^/]*$/, "") + '/torneos';
}

function _data_url_for_tid (tid) {
   return _data_url_base() + '/' + tid;
}

function _load_torneo (instance) {
   axios.get(_data_url_for_tid(instance.tid)).then(response => {
      instance.results = response.data;
      instance.has_torneo = true;
      instance.show_torneo = true;
      instance.show_new_torneo = false;
   });
};

const vm = new Vue({
   el: '#app',
   // Mock data for the value of BTC in USD
   data: {
      tid: null,
      newtid: null,
      has_torneo: false,
      round: {id: 0},
      results: {},
      show_torneo: false,
      show_new_torneo: true,
      new_torneo: {
         metadata: {title: ''},
         n: 3,
         participants: [
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
            {
               id: '',
               premium: false,
            },
         ],
      },
   },
   methods: {
      create_torneo: function () {
         var url = _data_url_base();
         axios.post(url, this.new_torneo)
            .then(response => {
               window.location.href = _page_url_for_tid(response.data.id);
         });
      },
      update_n_selection: function () {
         var n = this.new_torneo.n;
         var participants = this.new_torneo.participants;
         var n2 = n * n;
         while (participants.length > n2) {
            participants.pop();
         }
         while (participants.length < n2) {
            participants.push({id: '', premium: false});
         }
      },
      score_for: function (match, participant) {
         if ('scores' in match) {
            return match.scores[participant];
         }
         return 0;
      },
      set_round: function (rid) {
         this.round.id = rid;
      },
      is_active: function (rid) {
         return this.round.id === rid;
      },
      redirect_to_torneo: function () {
         window.location.href = _page_url_for_tid(this.newtid);
      },
      load_torneo: function () {
         _load_torneo(this);
      },
      reload: function () {
         var url = new URL(window.location.href);
         alert(url);
         axios.get(url).then(response => {
            this.results = response.data;
            this.has_torneo = true;
         })
      },
      save_scores: function (match) {
         axios.put(match.url.scores, match.scores)
            .then(res => { this.load_torneo(); });
      },
      has_tid: function () {
         return this.tid === null ? 0 : 1;
      },
      has_full_url: function () {
         var tid = this.tid;
         return tid === null ? false : tid.match(/-[a-zA-Z0-9]*$/);
      },
      full_url: function() {
         return _page_url_for_tid(this.tid);
      },
      public_url: function() {
         var tid = this.tid;
         tid = tid.replace(/-[a-zA-Z0-9]*$/, "");
         return _page_url_for_tid(tid);
      },
      setup_torneo: function() {
         this.has_torneo = false;
         this.show_torneo = false;
         this.show_new_torneo = true;
         this.tid = null;
      }
   },
   mounted() {
      var myurl = new URL(window.location.href);
      var q = myurl.searchParams;
      show_torneo = false;
      show_new_torneo = true;
      if (q.has('tid')) {
         this.tid = q.get('tid');
         _load_torneo(this);
      }
   }
});
