<template>
  <v-card>
    <v-row justify="end" style="padding-right:30px; padding-top:20px">
      <v-col cols="auto">
        <v-btn rounded width="150" height="60" @click="$store.dispatch('connectWallet')">{{ $store.state.connected ?
          'Disconnect' : 'Connect' }}</v-btn>
      </v-col>
      <v-col cols="auto" v-if="$store.state.connected">
        <v-btn rounded width="150" height="60" disabled>{{ $store.state.account.substring(0, 4) + "..." +
          $store.state.account.substring($store.state.account.length - 4, $store.state.account.length) }}</v-btn>
      </v-col>
    </v-row>
    <v-tabs v-model="tab" align-tabs="center" color="#fff3e2" style="padding-top:10px">
      <v-tab value="1">Deploy IP Holder</v-tab>
      <v-tab value="2">Public IPs</v-tab>
      <v-tab value="3">MY IP Holders</v-tab>
      <v-tab value="4">My Bought Licenses</v-tab>

    </v-tabs>
    <v-window v-model="tab">
      <v-window-item key="1" value="1">
        <v-container fluid>
          <MintIP></MintIP>
        </v-container>
      </v-window-item>
      <v-window-item key="2" value="2">
        <v-container fluid>
          <PublicIP></PublicIP>
        </v-container>
      </v-window-item>
      <v-window-item key="3" value="3">
        <v-container fluid>
          <MyIPs></MyIPs>
        </v-container>
      </v-window-item>
      <v-window-item key="4" value="4">
        <v-container fluid>
          <MyBoughtLicenses></MyBoughtLicenses>
        </v-container>
      </v-window-item>
    </v-window>
  </v-card>
</template>
<script>
import MintIP from './MintIPHolder.vue'
import MyIPs from './MyIPHolders.vue'
import PublicIP from './PublicIPs.vue'
import MyBoughtLicenses from './MyBoughtLicenses.vue'

export default {
  components: { MintIP, MyIPs, PublicIP,MyBoughtLicenses },
  data: () => ({
    tab: null,
  }),
  mounted() {
    this.$store.dispatch('connectWallet')
  }
}
</script>