<template>
  <v-container fluid>
    <v-sheet
      class="mx-auto"
      width="500"
    >
      <v-form ref="form">
        <v-text-field
          readonly
          v-model="form.paymentToken.address"
          label="Payment Token Address"
          required
        />
        <v-text-field
          readonly
          v-model="form.paymentToken.name"
          label="Payment Token Name"
          required
        />
        <v-text-field
          readonly
          v-model="form.paymentToken.symbol"
          label="Payment Token Symbol"
          required
        />
        <v-text-field
          readonly
          v-model="form.paymentToken.decimals"
          label="Payment Token Decimals"
          required
        />
  
        <div class="d-flex flex-column">
          <v-btn
            :loading="$store.state.isLoading"
            class="mt-4"
            color="#fff3e2"
            block
            @click="submit"
          >
            Deploy
          </v-btn>
        </div>
      </v-form>
    </v-sheet>
  </v-container>
</template>
  <script>
  const web3Utils = require("web3-utils");
  export default {
    watch: {
      "$store.state.paymentTokenDetails": function (newVal, oldVal) {
        this.form.paymentToken = newVal;
        console.log("form: ", this.form.paymentToken);
      },
    },
    data: () => ({
      costRules: [
        (v) => !!v || "Cost is required",
        (v) => (v && !isNaN(v) && isFinite(v)) || "Cost must be greater than 0",
      ],
      nameRules: [
        (v) => !!v || "Field is required",
        (v) => (v && v.length >= 5) || "Field must be greater than 5 characters",
      ],
      descriptionRules: [
        (v) => !!v || "Description is required",
        (v) =>
          (v && v.length >= 50) ||
          "Description must be greater than 50 characters",
      ],
      rules: [
        (value) => {
          return (
            !value ||
            !value.length ||
            value[0].size < 2000000 ||
            "File size should be less than 2 MB!"
          );
        },
      ],
      addressRules: [
        (v) => !!v || "Token Adrress is required",
        (v) => (v && web3Utils.isAddress(v)) || "Invalid address ",
      ],
      explode: false,
      form: {
        ipName: "",
        ipDescription: "",
        paymentToken: {},
        licenseCost: "",
        termsAndConditions: {},
      },
    }),
    components: {},
  
    methods: {
      submit: async function () {
        const { valid } = await this.$refs.form.validate();
        if (valid) {
          this.$store.dispatch("deployIP", this.form);
        }
      },
    },
  };
  </script>
  