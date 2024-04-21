<template>
  <v-bottom-sheet v-model="$store.state.showIpDialog" class="mx-auto">
    <v-card>
      <v-card-title style="font-size: 13px">
        <a
          :href="
            'https://sepolia.etherscan.io/address/' +
            $store.state.selectedIP.address
          "
          target="_blank"
          style="text-decoration: underline; color: blue"
        >
          IP Holder Sepolia Scan
        </a>
      </v-card-title>
      <v-tabs
        v-model="tab"
        align-tabs="center"
        color="#ffd4a9"
        style="height: 60px"
      >
        <v-tab value="1">Mint IP</v-tab>
        <v-tab value="2">my IPs</v-tab>
      </v-tabs>
      <v-window v-model="tab">
        <v-window-item key="1" value="1">
          <v-container fluid>
            <v-sheet class="mx-auto" width="500">
              <v-form ref="form">
                <v-text-field
                  v-model="form.ipName"
                  hint="This is the name of the IP Asset"
                  :rules="nameRules"
                  label="IP Name"
                  required
                  variant="underlined"
                ></v-text-field>
                <v-textarea
                  v-model="form.ipDescription"
                  :rules="descriptionRules"
                  counter="50"
                  hint="A short description of the IP Asset"
                  label="IP Schema Description"
                  name="input-7-1"
                  variant="underlined"
                  auto-grow
                ></v-textarea>

                <v-row>
                  <v-col cols="8">
                    <v-file-input
                      v-model="form.file"
                      hint="IP File to be attached"
                      label="IP file"
                      accept="application/pdf,image/*"
                      :rules="fileRules"
                      show-size
                    ></v-file-input>
                  </v-col>
                  <v-col cols="4">
                    <v-btn
                      height="45px"
                      :loading="$store.state.isLoading"
                      class="mt-4"
                      color="#ffd4a9"
                      block
                      @click="uploadFile"
                    >
                      Upload
                    </v-btn>
                  </v-col>
                </v-row>
                <v-checkbox
                  :rules="[(v) => !!v || 'You must agree to continue!']"
                  color="black"
                  v-model="form.terms"
                >
                  <template v-slot:label>
                    <div style="font-size: 13px">
                      By Default the IP will be minted as
                      <v-tooltip location="bottom">
                        <template v-slot:activator="{ props }">
                          <a
                            href="https://docs.storyprotocol.xyz/docs/pil-flavors-preset-policy#flavor-1-non-commercial-social-remixing"
                            target="_blank"
                            v-bind="props"
                            @click.stop
                          >
                            Non-Commercial Social Remixing
                          </a>
                        </template>
                        Opens in new window
                      </v-tooltip>
                      Do you agree?
                    </div>
                  </template>
                </v-checkbox>
                <div class="d-flex flex-column">
                  <v-btn
                    :loading="$store.state.isLoading"
                    class="mt-4"
                    color="#ffd4a9"
                    block
                    @click="mintIP"
                  >
                    Mint IP
                  </v-btn>
                </div>
              </v-form>
            </v-sheet>
          </v-container>
        </v-window-item>
        <v-window-item key="2" value="2">
          <IssuedLinceses></IssuedLinceses>
        </v-window-item>
      </v-window>

      <v-card-text>
        <v-row align="center" justify="center">
          <v-btn
            color="#ffd4a9"
            variant="text"
            @click="$store.state.showIpDialog = false"
          >
            Close
          </v-btn>
        </v-row>
      </v-card-text>
    </v-card>
  </v-bottom-sheet>
</template>
<script>
import IssuedLinceses from "./IssuedLinceses.vue";
export default {
  components: { IssuedLinceses },
  beforeMount() {
    this.form.paymentToken = this.$store.state.paymentTokenDetails;
  },
  beforeUnmount() {
    this.form = {
      url: "",
      ipName: "",
      ipDescription: "",
      paymentToken: {},
      licenseCost: "",
      file: {},
      terms: false,
      metadata: {
        external_link: "",
        fileURI: "",
        description: "",
        attributes: [],
        name: "",
      },
    };
  },
  methods: {
    async validForm() {
      const { valid } = await this.$refs.form.validate();
      console.log("valid: ", valid);
      return valid;
    },
    async uploadFile() {
      if (!this.validForm()) {
        return;
      }
      const uri = await this.$store.dispatch("uploadFile", {
        file: this.form.file,
      });
      if (uri.success) {
        this.form.metadata.external_link = uri.uri;
      }
    },
    mintIP() {
      if (!this.validForm()) {
        return;
      }
      if (this.form.metadata.external_link.length === 0) {
        this.$store.dispatch(
          "toastWarning",
          "Please upload  IP Asset file before minting"
        );
        return;
      }
      this.form.metadata = {
        external_link: this.form.metadata.external_link,
        fileURI: this.form.metadata.external_link,
        description: this.form.ipDescription,
        attributes: [],
        name: this.form.ipName,
      };
      this.$store.dispatch("mintIP", { form: this.form });
    },
  },
  data() {
    return {
      urlRules: [
        (url) => {
          const pattern = new RegExp(
            "^(https?:\\/\\/)?" + // protocol
              "((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|" + // domain name
              "((\\d{1,3}\\.){3}\\d{1,3}))" + // OR ip (v4) address
              "(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*" + // port and path
              "(\\?[;&a-z\\d%_.~+=-]*)?" + // query string
              "(\\#[-a-z\\d_]*)?$",
            "i"
          ); // fragment locator
          if (!url) {
            return "Please provide a URL.";
          }
          if (!pattern.test(url)) {
            return "Please enter a valid URL.";
          }
          return true;
        },
      ],
      tab: null,
      form: {
        url: "",
        ipName: "",
        ipDescription: "",
        paymentToken: {},
        licenseCost: "",
        file: {},
        terms: false,
        metadata: {
          external_link: "",
          fileURI: "",
          description: "",
          attributes: [],
          name: "",
        },
      },
      dialog: false,
      issuedLicenses: [],
      nameRules: [
        (v) => !!v || "Field is required",
        (v) =>
          (v && v.length >= 5) || "Field must be greater than 5 characters",
      ],
      descriptionRules: [
        (v) => !!v || "Description is required",
        (v) =>
          (v && v.length <= 50) ||
          "Description must be less than and equal to 50 characters",
      ],
      fileRules: [
        (value) => {
          if (!value || !value.length) {
            return "Please select a file.";
          }
          if (value[0].size >= 2000000) {
            // Checks if the file size is 2MB or more
            return "File size should be less than 2 MB!";
          }

          return true;
        },
      ],
    };
  },
};
</script>
