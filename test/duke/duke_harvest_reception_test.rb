require 'test_helper'
class DukeHarvestReceptionTest < Minitest::Test
  def setup
    @reception = Duke::DukeHarvestReception.new(user_input: "Réception de vendanges avec une acidité de 10, 11g d'acide malique température de 12 degrés 13 hectos, tavp de 14.1 degrés ph à 5,6, azote aminé à 15, azote ammoniacal égal à 16 mg, 17 mg/l d'azote assimilable sain avec de la pourriture")
  end

  def test_can_extract_reception_parameters
    @reception.extract_reception_parameters
    %I[temperature tav quantity ph amino_nitrogen ammoniacal_nitrogen assimilated_nitrogen sanitarystate h2so4
       malic].each do |param|
      refute_nil @reception.parameters[param.to_s], "Cannot extract reception parameter #{param}"
    end
    refute_match(/(\d{}|sain|pourriture|acidité|malique|température|tavp|ph|azote)/, @reception.user_input,
                 'Input same after extraction')
  end
end
