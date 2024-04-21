<template>
  <v-container fluid>
    <v-row
      height="500"
      v-if="$store.state.issuedIPs.length === 0"
      align="center"
      justify="center"
    >
      No Minted Licenses found
    </v-row>

    <v-row v-else>
      <v-col v-for="(ip, i) in $store.state.issuedIPs" :key="i" cols="12" md="4">
        <v-card max-width="344">
          <v-img
            cover
            :aspect-ratio="1"
            class="bg-white"
            v-if="ip.isPDF"
            src="https://st5.depositphotos.com/74552810/62639/v/450/depositphotos_626399352-stock-illustration-pdf-file-icon-white-background.jpg"
          ></v-img>
          <v-img cover :aspect-ratio="1" class="bg-white" :src="ip.url" v-else>
          </v-img>
          <v-row>
            <v-card-item>
              <v-card-title style="font-size: 14px">
                IP Name:
                {{ ip.ipName }}
              </v-card-title>
              <v-card-subtitle style="font-size: 14px">
                Address:
                <a
                  :href="
                    'https://sepolia.etherscan.io/address/' + ip.ipIdAccount
                  "
                  target="_blank"
                  style="text-decoration: underline; color: blue"
                >
                  View on Sepolia Scan
                </a>
              </v-card-subtitle>
              <v-card-subtitle style="font-size: 14px">
                Total License Sales ({{ ip.paymentTokenSymbol }}):
                {{ ip.sales }}
              </v-card-subtitle>
              <v-card-subtitle style="font-size: 14px">
                Cost ({{ ip.paymentTokenSymbol }}): {{ ip.cost }}
              </v-card-subtitle>
            </v-card-item>
          </v-row>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn
              v-if="ip.isPDF"
              @click="downloadPDF(ip.url)"
              color="#632b2b"
              variant="text"
            >
              Download PDF
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import { saveAs } from "file-saver";
import axios from "axios";
export default {
  methods: {
    downloadPDF(URL) {
      axios.get(URL, { responseType: "blob" }).then((response) => {
        saveAs(response.data, "downloaded-file.pdf");
      });
    },
  },
};
</script>

<style></style>
