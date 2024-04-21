<template>
    <v-container fluid>
      <v-row v-if="$store.state.ips.length === 0" align="center" justify="center">
        No IP Holders found
      </v-row>
      <v-row v-else>
        <v-col v-for="(ip, i) in $store.state.ips" :key="i" cols="12" md="4">
          <v-card class="mx-auto" max-width="344">
            <VueBlockies :seed="ip.address" :size="100" />
            <v-card-actions>
              <v-spacer></v-spacer>
              <v-btn
                color="#632b2b"
                variant="text"
                @click="showIPIntanceDetails(ip)"
              >
                View
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-col>
      </v-row>
      <IPInstance></IPInstance>
    </v-container>
  </template>
  
  <script>
  import VueBlockies from "vue-blockies";
  import IPInstance from "../components/IPInstance.vue";
  
  export default {
    components: {
      VueBlockies,
      IPInstance,
    },
    data: () => ({
      explode: false,
    }),
    async beforeMount() {
      await this.$store.dispatch("loadUserIPs");
    },
    methods: {
      showIPIntanceDetails: async function (ip) {
        this.$store.state.showIpDialog = true;
        this.$store.state.selectedIP = ip;
        console.log("selectedIP: ", this.$store.state.selectedIP);
        await this.$store.dispatch("getMintedIPs");
      },
      list: async function () {},
      unList: async function () {},
    },
  };
  </script>
  